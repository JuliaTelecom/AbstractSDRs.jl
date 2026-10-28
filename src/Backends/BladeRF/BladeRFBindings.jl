module BladeRFBindings

# --- Print radio config
include("../../Printing.jl");
using .Printing

# -- Loading driver bindings 
include("./LibBladeRF.jl")
using  .LibBladeRF

using Printf

# Methods extension 
import Base:close;


# Symbols exportation 
export openBladeRF
export updateCarrierFreq!;
export updateSamplingRate!;
export updateBandwidth!;
export updateBandwidth!;
export updateGain!; 
export updateBiasTee!;
export updateRFPort!;
export updateRxFIR!;
export recv;
export recv!;
export print;
export BladeRFBinding;

# ----------------------------------------------------
# --- High level structures 
# ---------------------------------------------------- 
mutable struct BladeRFRxWrapper
    channel::Int
    buffer::Vector{Int16}
    ptr_metadata::Ref{bladerf_metadata}
end
mutable struct BladeRFTxWrapper
    channel::Int
    buffer::Vector{Int16}
    ptr_metadata::Ref{bladerf_metadata}
end
# --- Main Rx structure 
mutable struct BladeRFRx
    bladerf::BladeRFRxWrapper
    carrierFreq::bladerf_frequency
    samplingRate::bladerf_sample_rate
    gain::bladerf_gain 
    rfBandwidth::bladerf_bandwidth
    antenna::String
    packetSize::Csize_t
    released::Int
end



# --- Main Tx structure 
mutable struct BladeRFTx 
    bladerf::BladeRFTxWrapper
    carrierFreq::bladerf_frequency
    samplingRate::bladerf_sample_rate
    gain::bladerf_gain 
    rfBandwidth::bladerf_bandwidth
    antenna::String
    packetSize::Csize_t
    released::Int
end

# --- Complete structure 
mutable struct BladeRFBinding
    radio::Ref{Ptr{bladerf}}
    rx::BladeRFRx 
    tx::BladeRFTx
    released::Bool
end


# ----------------------------------------------------
# --- Methods call
# ---------------------------------------------------- 


""" 
Init an empty string of size n, filled with space. Usefull to have container to get string from UHD.
"""
initEmptyString(n) = String(ones(UInt8,n)*UInt8(32))

function _check_status(status::Integer, context::AbstractString; fatal::Bool=true)
    if status < 0
        msg = unsafe_string(bladerf_strerror(status))
        if fatal
            error("bladeRF: $context failed (status=$status): $msg")
        else
            @warn "bladeRF: $context failed (status=$status): $msg"
        end
    end
    return status
end

# The synchronous stream API expects a buffer size aligned to libbladeRF constraints.
# In this backend, stream buffer_size is configured as packet_size * 2 (I + Q Int16 paths),
# so packet_size must be a positive multiple of 512 complex samples.
function _normalize_packet_size(packet_size::Integer)
    if packet_size <= 0
        @warn "bladeRF: invalid packet_size=$packet_size, fallback to 4096"
        return 4096
    end
    aligned = cld(Int(packet_size), 512) * 512
    if aligned != packet_size
        @warn "bladeRF: packet_size=$packet_size adjusted to $aligned (required alignment: multiple of 512 complex samples)"
    end
    return aligned
end

function _resolve_gain_mode(mode)
    if mode isa bladerf_gain_mode
        return mode
    elseif mode isa Symbol
        mapping = Dict(
            :default => BLADERF_GAIN_DEFAULT,
            :agc => BLADERF_GAIN_DEFAULT,
            :manual => BLADERF_GAIN_MGC,
            :mgc => BLADERF_GAIN_MGC,
            :fastattack => BLADERF_GAIN_FASTATTACK_AGC,
            :fast_attack => BLADERF_GAIN_FASTATTACK_AGC,
            :slowattack => BLADERF_GAIN_SLOWATTACK_AGC,
            :slow_attack => BLADERF_GAIN_SLOWATTACK_AGC,
            :hybrid => BLADERF_GAIN_HYBRID_AGC,
            :hybrid_agc => BLADERF_GAIN_HYBRID_AGC,
        )
        haskey(mapping, mode) || error("bladeRF: unsupported gain_mode=$mode")
        return mapping[mode]
    else
        error("bladeRF: unsupported gain_mode type $(typeof(mode))")
    end
end

function _resolve_rfic_rxfir(mode)
    if mode isa bladerf_rfic_rxfir
        return mode
    elseif mode isa Symbol
        mapping = Dict(
            :default => BLADERF_RFIC_RXFIR_DEFAULT,
            :normal => BLADERF_RFIC_RXFIR_DEC1,
            :dec1 => BLADERF_RFIC_RXFIR_DEC1,
            :bypass => BLADERF_RFIC_RXFIR_BYPASS,
            :custom => BLADERF_RFIC_RXFIR_CUSTOM,
            :dec2 => BLADERF_RFIC_RXFIR_DEC2,
            :dec4 => BLADERF_RFIC_RXFIR_DEC4,
        )
        haskey(mapping, mode) || error("bladeRF: unsupported rx_fir=$mode")
        return mapping[mode]
    else
        error("bladeRF: unsupported rx_fir type $(typeof(mode))")
    end
end

function _get_rf_port(dev, ch)
    port = Ref{Ptr{Cchar}}(C_NULL)
    status = bladerf_get_rf_port(dev, ch, port)
    _check_status(status, "get RF port"; fatal=false)
    return port[] == C_NULL ? "" : unsafe_string(port[])
end

_normalize_rf_port(port::AbstractString) = port
_normalize_rf_port(port::Symbol) = String(port)

# udev rules  --> /etc/rules.d/88-nuand-bladerf2.rules
# # Nuand bladeRF 2.0 micro
# ATTR{idVendor}=="2cf0", ATTR{idProduct}=="5250", MODE="660", GROUP="@BLADERF_GROUP@"

function openBladeRF(
    carrierFreq,
    samplingRate,
    gain;
    gain_mode=BLADERF_GAIN_MGC,
    bandwidth=nothing,
    packet_size=4096,
    packetSize=nothing,
    rx_port=nothing,
    tx_port=nothing,
    rx_fir=nothing,
    biastee_rx=true,
    biastee_tx=false
)
    if !isnothing(packetSize)
        packet_size = packetSize
    end
    packet_size = _normalize_packet_size(Int(packet_size))
    requested_bandwidth = isnothing(bandwidth) ? samplingRate*0.50 : bandwidth
    selected_gain_mode = _resolve_gain_mode(gain_mode)

    # ----------------------------------------------------
    # --- Create Empty structure to open radio
    # ----------------------------------------------------
    ptr_bladerf = Ref{Ptr{bladerf}}()
    status = bladerf_open(ptr_bladerf, "")
    #@info "Open BladeRF with status $status"

    if status < 0
        @error "Unable to open the BladeRF SDR. Status error $status"
        return nothing
    end

    # Load FPGA
    #status = bladerf_load_fpga(ptr_bladerf[],"./hostedxA9.rbf")
    #sleep(1)

    # Instantiate the first channels of the radio
    theChannelRx = LibBladeRF.BLADERF_CHANNEL_RX(0)
    theChannelTx = LibBladeRF.BLADERF_CHANNEL_TX(0)

    # Defaults used for struct creation, updated during configuration
    effective_carrierFreq_rx = convert(bladerf_frequency, carrierFreq)
    effective_sampling_rate_rx = convert(bladerf_sample_rate, samplingRate)
    effective_rf_bandwidth_rx = convert(bladerf_bandwidth, requested_bandwidth)
    effective_gain_rx = convert(bladerf_gain, gain)
    effective_carrierFreq_tx = convert(bladerf_frequency, carrierFreq)
    effective_sampling_rate_tx = convert(bladerf_sample_rate, samplingRate)
    effective_rf_bandwidth_tx = convert(bladerf_bandwidth, requested_bandwidth)
    effective_gain_tx = convert(bladerf_gain, gain)

    try
        # Force baseband receive path to avoid stale loopback/mux state from another app.
        status = bladerf_set_loopback(ptr_bladerf[], BLADERF_LB_NONE)
        _check_status(status, "set loopback mode to none"; fatal=false)
        status = bladerf_set_rx_mux(ptr_bladerf[], BLADERF_RX_MUX_BASEBAND)
        _check_status(status, "set RX mux to baseband"; fatal=false)

        # ----------------------------------------------------
        # --- Rx Configuration
        # ----------------------------------------------------
        status = bladerf_set_frequency(ptr_bladerf[], theChannelRx, convert(bladerf_frequency, carrierFreq))
        _check_status(status, "set RX frequency")
        container_rx_freq = Ref{bladerf_frequency}(0)
        status = bladerf_get_frequency(ptr_bladerf[], theChannelRx, container_rx_freq)
        _check_status(status, "get RX frequency")
        effective_carrierFreq_rx = container_rx_freq[]

        container_rx_sr = Ref{bladerf_sample_rate}(0)
        status = bladerf_set_sample_rate(ptr_bladerf[], theChannelRx, convert(bladerf_sample_rate, samplingRate), container_rx_sr)
        _check_status(status, "set RX sample rate")
        effective_sampling_rate_rx = container_rx_sr[]

        container_rx_bw = Ref{bladerf_bandwidth}(0)
        status = bladerf_set_bandwidth(ptr_bladerf[], theChannelRx, convert(bladerf_bandwidth, requested_bandwidth), container_rx_bw)
        _check_status(status, "set RX bandwidth")
        effective_rf_bandwidth_rx = container_rx_bw[]

        if !isnothing(rx_port)
            status = bladerf_set_rf_port(ptr_bladerf[], theChannelRx, _normalize_rf_port(rx_port))
            _check_status(status, "set RX RF port")
        end

        if !isnothing(rx_fir)
            status = bladerf_set_rfic_rx_fir(ptr_bladerf[], _resolve_rfic_rxfir(rx_fir))
            _check_status(status, "set RX RFIC FIR")
        end

        status = bladerf_set_gain_mode(ptr_bladerf[], theChannelRx, selected_gain_mode)
        _check_status(status, "set RX gain mode")
        status = bladerf_set_gain(ptr_bladerf[], theChannelRx, convert(bladerf_gain, gain))
        _check_status(status, "set RX gain")
        container_rx_gain = Ref{bladerf_gain}(0)
        status = bladerf_get_gain(ptr_bladerf[], theChannelRx, container_rx_gain)
        _check_status(status, "get RX gain")
        effective_gain_rx = container_rx_gain[]
        status = bladerf_set_bias_tee(ptr_bladerf[], theChannelRx, biastee_rx)
        _check_status(status, "set RX bias tee")
        effective_rx_port = _get_rf_port(ptr_bladerf[], theChannelRx)

        # ----------------------------------------------------
        # --- Tx config
        # ----------------------------------------------------
#=        status = bladerf_set_frequency(ptr_bladerf[], theChannelTx, convert(bladerf_frequency, carrierFreq))=#
        #=_check_status(status, "set TX frequency")=#
        #=container_tx_freq = Ref{bladerf_frequency}(0)=#
        #=status = bladerf_get_frequency(ptr_bladerf[], theChannelTx, container_tx_freq)=#
        #=_check_status(status, "get TX frequency")=#
        #=effective_carrierFreq_tx = container_tx_freq[]=#

        #=container_tx_sr = Ref{bladerf_sample_rate}(0)=#
        #=status = bladerf_set_sample_rate(ptr_bladerf[], theChannelTx, convert(bladerf_sample_rate, samplingRate), container_tx_sr)=#
        #=_check_status(status, "set TX sample rate")=#
        #=effective_sampling_rate_tx = container_tx_sr[]=#

        #=container_tx_bw = Ref{bladerf_bandwidth}(0)=#
        #=status = bladerf_set_bandwidth(ptr_bladerf[], theChannelTx, convert(bladerf_bandwidth, requested_bandwidth), container_tx_bw)=#
        #=_check_status(status, "set TX bandwidth")=#
        #=effective_rf_bandwidth_tx = container_tx_bw[]=#

        #=status = bladerf_set_gain(ptr_bladerf[], theChannelTx, convert(bladerf_gain, gain))=#
        #=_check_status(status, "set TX gain")=#
        #=container_tx_gain = Ref{bladerf_gain}(0)=#
        #=status = bladerf_get_gain(ptr_bladerf[], theChannelTx, container_tx_gain)=#
        #=_check_status(status, "get TX gain")=#
        #=effective_gain_tx = container_tx_gain[]=#
        #=status = bladerf_set_bias_tee(ptr_bladerf[], theChannelTx, biastee_tx)=#
        #=_check_status(status, "set TX bias tee")=#

        container_tx_freq = Ref{bladerf_frequency}(0)
        effective_carrierFreq_tx = container_tx_freq[]

        container_tx_sr = Ref{bladerf_sample_rate}(0)
        effective_sampling_rate_tx = container_tx_sr[]

        container_tx_bw = Ref{bladerf_bandwidth}(0)
        effective_rf_bandwidth_tx = container_tx_bw[]

        container_tx_gain = Ref{bladerf_gain}(0)
        effective_gain_tx = container_tx_gain[]
        if !isnothing(tx_port)
            status = bladerf_set_rf_port(ptr_bladerf[], theChannelTx, _normalize_rf_port(tx_port))
            _check_status(status, "set TX RF port")
        end
        effective_tx_port = _get_rf_port(ptr_bladerf[], theChannelTx)


        # ----------------------------------------------------
        # --- Configure Rx Streamer as sync structure
        # ----------------------------------------------------
        
        status = bladerf_sync_config(ptr_bladerf[], BLADERF_RX_X1, BLADERF_FORMAT_SC16_Q11_META, 16, packet_size * 2, 8, 10000)
        _check_status(status, "configure RX stream")
        status = bladerf_enable_module(ptr_bladerf[], BLADERF_RX, true)
        _check_status(status, "enable RX module")

        # Metadata
        metadata_rx = bladerf_metadata(bladerf_timestamp(0), BLADERF_META_FLAG_RX_NOW, 1, 1, ntuple(x -> UInt8(1), 32))
        ptr_metadata_rx = Ref{bladerf_metadata}(metadata_rx)

        # ----------------------------------------------------
        # --- Configure Tx Streamer as sync structure
        # ----------------------------------------------------
       #= status = bladerf_sync_config(ptr_bladerf[], BLADERF_TX_X1, BLADERF_FORMAT_SC16_Q11_META, 16, packet_size * 2, 8, 10000)=#
        #=_check_status(status, "configure TX stream")=#
        #=status = bladerf_enable_module(ptr_bladerf[], BLADERF_TX, true)=#
        #=_check_status(status, "enable TX module")=#

        # Metadata
        flag = BLADERF_META_FLAG_TX_BURST_START | BLADERF_META_FLAG_TX_NOW | BLADERF_META_FLAG_TX_BURST_END
        metadata_tx = bladerf_metadata(bladerf_timestamp(0), flag, 1, 1, ntuple(x -> UInt8(1), 32))
        ptr_metadata_tx = Ref{bladerf_metadata}(metadata_tx)

        # ----------------------------------------------------
        # --- Wrap all into a custom structure
        # ----------------------------------------------------
        # Instantiate a buffer to handle async receive. Size is arbritrary and will be modified afterwards
        bufferTx = zeros(Int16, packet_size * 2)
        bufferRx = zeros(Int16, packet_size * 2)
        bladeRFRx = BladeRFRxWrapper(theChannelRx, bufferRx, ptr_metadata_rx)
        bladeRFTx = BladeRFTxWrapper(theChannelTx, bufferTx, ptr_metadata_tx)
        rx = BladeRFRx(
                      bladeRFRx,
                      effective_carrierFreq_rx,
                      effective_sampling_rate_rx,
                      effective_gain_rx,
                      effective_rf_bandwidth_rx,
                      effective_rx_port,
                      packet_size,
                      0
                     )
        tx = BladeRFTx(
                      bladeRFTx,
                      effective_carrierFreq_tx,
                      effective_sampling_rate_tx,
                      effective_gain_tx,
                      effective_rf_bandwidth_tx,
                      effective_tx_port,
                      packet_size,
                      0
                     )
        radio = BladeRFBinding(
                              ptr_bladerf,
                              rx,
                              tx,
                              false
        )
        return radio
    catch err
        bladerf_close(ptr_bladerf[])
        rethrow(err)
    end
end

function Base.print(rx::BladeRFRx);
    strF  = @sprintf("Carrier Frequency: %2.3f MHz\nSampling Frequency: %2.3f MHz\nRF Bandwidth: %2.3f MHz\nGain: %2.3f\nRF Port: %s",rx.carrierFreq/1e6,rx.samplingRate/1e6,rx.rfBandwidth/1e6,rx.gain,rx.antenna)
    @inforx "Current BladeRF Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(tx::BladeRFTx);
    strF  = @sprintf("Carrier Frequency: %2.3f MHz\nSampling Frequency: %2.3f MHz\nRF Bandwidth: %2.3f MHz\nGain: %2.3f\nRF Port: %s",tx.carrierFreq/1e6,tx.samplingRate/1e6,tx.rfBandwidth/1e6,tx.gain,tx.antenna)
    @infotx "Current BladeRF Radio Configuration in Tx mode\n$strF"; 
end
function Base.print(radio::BladeRFBinding)
    print(radio.rx);
    print(radio.tx);
end



""" Returns the channel index associated to the current TX/RX 
"""
function getChannel(head::Union{BladeRFTx,BladeRFRx})
    return head.bladerf.channel 
end


""" Update the carrier frequency of the blade RF 
"""
function updateCarrierFreq!(radio::BladeRFBinding,frequency)
    # Update Rx head 
    bladerf_set_frequency(radio.radio[],getChannel(radio.rx),convert(bladerf_frequency,frequency))
    container = Ref{bladerf_frequency}(0)
    bladerf_get_frequency(radio.radio[],getChannel(radio.rx),container)
    effective_carrierFreq = container[] 
    radio.rx.carrierFreq = effective_carrierFreq 
    # Update Tx head 
        bladerf_set_frequency(radio.radio[],getChannel(radio.tx),convert(bladerf_frequency,frequency))
    container = Ref{bladerf_frequency}(0)
    bladerf_get_frequency(radio.radio[],getChannel(radio.tx),container)
    effective_carrierFreq = container[] 
    radio.tx.carrierFreq = effective_carrierFreq 
end 


""" Get the ratio between the sampling rate and the BW 
"""
function get_bw_samp_ratio(radio::BladeRFBinding)
    sampling_rate = radio.rx.samplingRate
    bandwidth = radio.rx.rfBandwidth
    return bandwidth / sampling_rate
end

""" Update the sampling frequency 
""" 
function updateSamplingRate!(radio::BladeRFBinding,samplingRate)
    r = get_bw_samp_ratio(radio)
    # Rx Head 
    container = Ref{bladerf_sample_rate}(0)
    status = bladerf_set_sample_rate(radio.radio[],getChannel(radio.rx),convert(bladerf_sample_rate,samplingRate),container)
    effective_sampling_rate  = container[]
    radio.rx.samplingRate = effective_sampling_rate
    # Tx Head 
    container = Ref{bladerf_sample_rate}(0)
    status = bladerf_set_sample_rate(radio.radio[],getChannel(radio.tx),convert(bladerf_sample_rate,samplingRate),container)
    effective_sampling_rate  = container[]
    radio.tx.samplingRate = effective_sampling_rate
    updateBandwidth!(radio,effective_sampling_rate * r) # We update the bandwidth to keep the same ratio with the sampling rate
end

""" Update the sampling frequency 
""" 
function updateBandwidth!(radio::BladeRFBinding,rfBandwidth)
    # Rx Head 
    container = Ref{bladerf_bandwidth}(0)
    status = bladerf_set_bandwidth(radio.radio[],getChannel(radio.rx),convert(bladerf_bandwidth,rfBandwidth),container)
    effective_sampling_rate  = container[]
    radio.rx.rfBandwidth = effective_sampling_rate
    # Tx Head 
    container = Ref{bladerf_bandwidth}(0)
    status = bladerf_set_bandwidth(radio.radio[],getChannel(radio.tx),convert(bladerf_bandwidth,rfBandwidth),container)
    effective_sampling_rate  = container[]
    radio.tx.rfBandwidth = effective_sampling_rate 
end


""" Update BladeRF Gain 
"""
function updateGain!(radio::BladeRFBinding,gain)
    # Update Rx head 
    bladerf_set_gain(radio.radio[],getChannel(radio.rx),convert(bladerf_gain,gain))
    container = Ref{bladerf_gain}(0)
    bladerf_get_gain(radio.radio[],getChannel(radio.rx),container)
    effective_gain = container[] 
    radio.rx.gain = effective_gain 
    # Update Tx head 
    bladerf_set_gain(radio.radio[],getChannel(radio.tx),convert(bladerf_gain,gain))
    container = Ref{bladerf_gain}(0)
    bladerf_get_gain(radio.radio[],getChannel(radio.tx),container)
    effective_gain = container[] 
    radio.tx.gain = effective_gain 
end 

""" Update bladeRF bias tee state for RX and/or TX channels. """
function updateBiasTee!(radio::BladeRFBinding; rx=nothing, tx=nothing)
    if !isnothing(rx)
        status = bladerf_set_bias_tee(radio.radio[], getChannel(radio.rx), Bool(rx))
        _check_status(status, "set RX bias tee")
    end
    if !isnothing(tx)
        status = bladerf_set_bias_tee(radio.radio[], getChannel(radio.tx), Bool(tx))
        _check_status(status, "set TX bias tee")
    end
end

""" Update the active bladeRF RF port for RX and/or TX channels. """
function updateRFPort!(radio::BladeRFBinding; rx=nothing, tx=nothing)
    if !isnothing(rx)
        status = bladerf_set_rf_port(radio.radio[], getChannel(radio.rx), _normalize_rf_port(rx))
        _check_status(status, "set RX RF port")
        radio.rx.antenna = _get_rf_port(radio.radio[], getChannel(radio.rx))
    end
    if !isnothing(tx)
        status = bladerf_set_rf_port(radio.radio[], getChannel(radio.tx), _normalize_rf_port(tx))
        _check_status(status, "set TX RF port")
        radio.tx.antenna = _get_rf_port(radio.radio[], getChannel(radio.tx))
    end
end

""" Update the RX RFIC FIR filter. Useful to compare normal, dec2, and dec4 modes. """
function updateRxFIR!(radio::BladeRFBinding, mode)
    status = bladerf_set_rfic_rx_fir(radio.radio[], _resolve_rfic_rxfir(mode))
    _check_status(status, "set RX RFIC FIR")
    return nothing
end

""" Receive nbSamples from the radio. Allocates an external buffer. To do this without allocation, see recv! 
"""
function recv(radio::BladeRFBinding,nbSamples)
    # --- Create an empty buffer with the appropriate size 
    buffer = zeros(ComplexF32,nbSamples)
    # --- Call the bang method 
    recv!(buffer,radio)
    return buffer
end

""" Allocates the input buffer `buffer` with samples from the radio. 
"""
function recv!(buffer::Vector{Complex{Float32}},radio::BladeRFBinding)
    nS = length(buffer)
    p  = radio.rx.packetSize 
    nbB = nS ÷ p 
    cnt = 0
    for k ∈ 0:nbB-1
        # Populate the blade internal buffer 
        status = bladerf_sync_rx(radio.radio[], radio.rx.bladerf.buffer, p, radio.rx.bladerf.ptr_metadata, 10000);
        (status != 0) && (print("O"))
        # Fill the main buffer 
        populateBuffer!(buffer, radio.rx.bladerf.buffer,k*p,p)
        # Update number of received samples
        cnt += p
    end
    # Last call should take rest of samples 
    residu = nS - nbB*p 
    if residu > 0 
        bladerf_sync_rx(radio.radio[], radio.rx.bladerf.buffer, residu, radio.rx.bladerf.ptr_metadata, 10000);
        populateBuffer!(buffer, radio.rx.bladerf.buffer,nbB*p,residu)
        cnt += residu
    end
    return cnt
end

""" 
Take the Blade internal buffer and fill the output buffer (ComplexF32)
"""
function populateBuffer!(buffer::Vector{ComplexF32},bladeBuffer::Vector{Int16},index,burst_size)
    # SC16_Q11 samples are effectively 12-bit signed values carried in Int16.
    c = typemax(Int16) >> 4
    for n ∈ 1 : burst_size 
        buffer[index + n] = Float32.(bladeBuffer[2(n-1)+1])/c + 1im*Float32.(bladeBuffer[2(n-1)+2])/c
    end
end

#function getError(radio::BladeRFBinding,targetSample=0) #FIXME Radio or radio .rx ? 
    #status = radio.rx.bladerf.ptr_metadata[].status 
    #@u
    #if status != 0 
        ## We have an error parse it 
        #if (status & BLADERF_META_STATUS_OVERRUN) == 1
            #a = radio.rx.bladerf.ptr_metadata[].actual_count
            #print("O[$a/$targetSample]")
        #end 
        #if (status & BLADERF_META_STATUS_UNDERRUN)  == 1
           #print("U")
        #end 
    #end 
    #return status 
#end 
 

function send(radio::BladeRFBinding,buffer::Array{Complex{T}},cyclic::Bool =false) where {T<:AbstractFloat}
    # Size of buffer to send 
    nT = length(buffer)
    # Size of internal buffer 
    nI = length(radio.tx.bladerf.buffer) ÷ 2 # 2 paths
    # Number of complete bursts 
    nbB = nT ÷ nI
    # Size of residu 
    r = nT - nbB * nI

    nbE = 0 # Number of elements sent 
    # Buffers 
    while(true)
        for n ∈ 1 : nbB 
            # Current buffer 
            _fill_tx_buffer!(radio.tx.bladerf.buffer,buffer,(n-1)*nI,nI)
            # Conversion to internal representation 
            status = bladerf_sync_tx(radio.radio[], radio.tx.bladerf.buffer, nI , radio.tx.bladerf.ptr_metadata, 10000);
            if status == 0
                nbE += nI
            else 
                @error "Error when sending data : Status is $status"
            end
        end
        # Residu 
        if r > 0 
            _fill_tx_buffer!(radio.tx.bladerf.buffer,buffer,nbB*nI,r)
            status = bladerf_sync_tx(radio.radio[], radio.tx.bladerf.buffer, r , radio.tx.bladerf.ptr_metadata, 10000);
            if status == 0
                nbE += r
            else 
                @error "Error when sending data : Status is $status"
            end
        end 
        if cyclic == false 
            break 
        end
    end
    return nbE
end

function _fill_tx_buffer!(internal_buffer,buffer,offset,nI)
    vM = typemax(Int16) 
    @inbounds @simd for k ∈ 1 : nI 
        internal_buffer[2*(k-1)+1] = Int16(round(real(buffer[ offset + k] * vM))) >> 4
        internal_buffer[2*(k-1)+2] = Int16(round(imag(buffer[ offset + k] * vM))) >> 4
    end 
    return nothing
end


""" Destroy and safely release bladeRF object 
"""
function close(radio::BladeRFBinding)
    if radio.released == false 
        # Deactive radio module 
        status = bladerf_enable_module(radio.radio[], BLADERF_RX, false);
        status = bladerf_enable_module(radio.radio[], BLADERF_TX, false);
        # Safely close module
        bladerf_close(radio.radio[]);
        radio.released = true 
        radio.rx.released = true 
        radio.tx.released = true 
        @info "BladeRF is closed"
    else 
        @warn "Blade RF is already closed and released. Abort"
    end
    return nothing
end

function scan()
    # By default brute-forcing bladeRF open leads to the opening 
    # of the SDR => We do this and control the status 
    ptr_bladerf = Ref{Ptr{bladerf}}()
    status = bladerf_open(ptr_bladerf,"")
    if status < 0 
        # --- No BladeRF found 
        @info "No BladeRF device found"
        return "" 
    else 
        strall = "BladeRF found with reference: "
        strall *=  unsafe_string(bladerf_get_board_name(ptr_bladerf[]))
        strall *= "\n"
        # --- Device speed 
        speed = bladerf_device_speed(ptr_bladerf[])
        strall *= "Device speed : $speed\n"
        # --- Device infos
        ptr_dev_info = Ref{bladerf_devinfo}()
        bladerf_get_devinfo(ptr_bladerf[], ptr_dev_info)
        dev_info = ptr_dev_info[] 
        strall *= "USB Bus : $(dev_info.usb_bus), "
        strall *= "USB Address : $(dev_info.usb_addr)\n"
        strall *= "USB serial: $(ntuple_to_string(dev_info.serial))\n"
        strall *= "Nanufacturer: $(ntuple_to_string(dev_info.manufacturer))\n"
        strall *= "Product : $(ntuple_to_string(dev_info.product))\n"
        # Display the stuff
        @info strall
        # --- Release the SDR
        bladerf_close(ptr_bladerf[]);
        return strall
    end
end

""" Convert a Ntuple of type T into a string. Usefull for block containers of LibBladeRF that uses NTuple(N,CChar) to contains strings 
"""
  function ntuple_to_string(t::NTuple{N,Int8}) where {N}
      bytes = [UInt8.(t)...] # Convert and switch to vector
      z = findfirst(==(0x00), bytes)  # stop at C NUL terminator
      return z === nothing ? String(bytes) : String(bytes[1:z-1])
  end

end
