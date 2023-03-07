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
export updateGain!; 
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

# udev rules  --> /etc/rules.d/88-nuand-bladerf2.rules
# # Nuand bladeRF 2.0 micro
# ATTR{idVendor}=="2cf0", ATTR{idProduct}=="5250", MODE="660", GROUP="@BLADERF_GROUP@"

function openBladeRF(carrierFreq,samplingRate,gain;agc_mode=0,tuner_gain_mode=0,packet_size=4096)
    # ----------------------------------------------------
    # --- Create Empty structure to open radio 
    # ---------------------------------------------------- 
    ptr_bladerf = Ref{Ptr{bladerf}}()
    status = bladerf_open(ptr_bladerf,"")
    @info "Open BladeRF with status $status"

    # ----------------------------------------------------
    # --- Rx Configuration 
    # ---------------------------------------------------- 
    # Instantiate the first channel of the radio 
    theChannelRx = LibBladeRF.BLADERF_CHANNEL_RX(0)
    
    # --- Instantiate carrier freq 
    bladerf_set_frequency(ptr_bladerf[],theChannelRx,carrierFreq)
    container = Ref{bladerf_frequency}(0)
    bladerf_get_frequency(ptr_bladerf[],theChannelRx,container)
    effective_carrierFreq = container[]
    @info "status carrier freq is $status -> value $(container[])"

    # --- Instantiate ADC rate 
    container = Ref{bladerf_sample_rate}(0)
    status = bladerf_set_sample_rate(ptr_bladerf[],theChannelRx,convert(bladerf_sample_rate,samplingRate),container)
    @info "status sampling is $status -> value $(container[])"
    effective_sampling_rate  = container[]

    # --- Instantiate RF band 
    container = Ref{bladerf_bandwidth}(0)
    status = bladerf_set_bandwidth(ptr_bladerf[],theChannelRx,convert(bladerf_bandwidth,samplingRate),container)
    @info "status band is $status-> value $(container[])"
    effective_rf_bandwidth = container[]

    # --- Set up gain 
    status = bladerf_set_gain(ptr_bladerf[],theChannelRx,convert(bladerf_gain,gain))
    @info "status gain is $status"
    container = Ref{bladerf_gain}(0)
    bladerf_get_gain(ptr_bladerf[],theChannelRx,container)
    effective_gain = container[] 

    # ----------------------------------------------------
    # --- Tx config 
    # ---------------------------------------------------- 
    
    # Instantiate the first channel of the radio 
    theChannelTx = LibBladeRF.BLADERF_CHANNEL_TX(0)
    
    # --- Instantiate carrier freq 
    bladerf_set_frequency(ptr_bladerf[],theChannelTx,carrierFreq)
    container = Ref{bladerf_frequency}(0)
    bladerf_get_frequency(ptr_bladerf[],theChannelTx,container)
    effective_carrierFreq = container[]
    @info "status carrier freq is $status -> value $(container[])"

    # --- Instantiate ADC rate 
    container = Ref{bladerf_sample_rate}(0)
    status = bladerf_set_sample_rate(ptr_bladerf[],theChannelTx,convert(bladerf_sample_rate,samplingRate),container)
    @info "status sampling is $status -> value $(container[])"
    effective_sampling_rate  = container[]

    # --- Instantiate RF band 
    container = Ref{bladerf_bandwidth}(0)
    status = bladerf_set_bandwidth(ptr_bladerf[],theChannelTx,convert(bladerf_bandwidth,samplingRate),container)
    @info "status band is $status-> value $(container[])"
    effective_rf_bandwidth = container[]

    # --- Set up gain 
    status = bladerf_set_gain(ptr_bladerf[],theChannelTx,convert(bladerf_gain,gain))
    @info "status gain is $status"
    container = Ref{bladerf_gain}(0)
    bladerf_get_gain(ptr_bladerf[],theChannelTx,container)
    effective_gain = container[] 

    # ----------------------------------------------------
    # --- Configure Streamer as sync structure 
    # ---------------------------------------------------- 
    # API should customize the sync parameter 
    status = bladerf_sync_config(ptr_bladerf[],BLADERF_RX_X1,BLADERF_FORMAT_SC16_Q11,16,packet_size*2,8,10000)
    @info "Status for Rx - Sync is $status"
    # Enable the module
    status = bladerf_enable_module(ptr_bladerf[], BLADERF_RX, true);
    @info "Status for Rx Module is $status"

    # Metadata 
    metadata = bladerf_metadata(bladerf_timestamp(0),BLADERF_META_FLAG_RX_NOW,1,1,ntuple(x->UInt8(1), 32))
    ptr_metadata = Ref{bladerf_metadata}(metadata);


    # ----------------------------------------------------
    # --- Wrap all into a custom structure 
    # ----------------------------------------------------  
    # Instantiate a buffer to handle async receive. Size is arbritrary and will be modified afterwards 
    buffer = zeros(Int16,packet_size*2)
    bladeRFRx = BladeRFRxWrapper(theChannelRx,buffer,ptr_metadata)
    bladeRFTx = BladeRFTxWrapper(theChannelTx,buffer)
    rx = BladeRFRx(
                  bladeRFRx,
                  effective_carrierFreq,
                  effective_sampling_rate,
                  effective_gain,
                  effective_rf_bandwidth,
                  "RX",
                  packet_size,
                  0
                 );
    tx = BladeRFTx(
                  bladeRFTx,
                  effective_carrierFreq,
                  effective_sampling_rate,
                  effective_gain,
                  effective_rf_bandwidth,
                  "TX",
                  packet_size,
                  0
                 );    
    radio = BladeRFBinding(
                          ptr_bladerf,
                          rx,
                          tx,
                          false
    )
    return radio
end

function Base.print(rx::BladeRFRx);
    strF  = @sprintf("Carrier Frequency: %2.3f MHz\nSampling Frequency: %2.3f MHz\nRF Bandwidth: %2.3f MHz\nGain: %2.3f",rx.carrierFreq/1e6,rx.samplingRate/1e6,rx.rfBandwidth/1e6,rx.gain)
    @inforx "Current BladeRF Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(tx::BladeRFTx);
    strF  = @sprintf("Carrier Frequency: %2.3f MHz\nSampling Frequency: %2.3f MHz\nRF Bandwidth: %2.3f MHz\nGain: %2.3f",tx.carrierFreq/1e6,tx.samplingRate/1e6,tx.rfBandwidth/1e6,tx.gain)
    @infotx "Current BladeRF Radio Configuration in Rx mode\n$strF"; 
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



""" Update the sampling frequency 
""" 
function updateSamplingRate!(radio::BladeRFBinding,samplingRate)
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
end

""" Update the sampling frequency 
""" 
function updateRFBandwidth!(radio::BladeRFBinding,rfBandwidth)
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


function recv(radio::BladeRFBinding,nbSamples)
    #buffer = zeros(Int16,nbSamples * 2) 
    #status = bladerf_sync_rx(radio.radio[], buffer, nbSamples, radio.rx.bladerf.ptr_metadata, 1000);
    #return buffer 
    buffer = zeros(ComplexF32,nbSamples)
    recv!(buffer,radio)
    return buffer
end


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
        populateBuffer!(buffer, radio.rx.bladerf.buffer,k,p)
        # Update number of received samples
        cnt += radio.rx.bladerf.ptr_metadata[].actual_count
    end
    return cnt
end

""" 
Take the Blade internal buffer and fill the output buffer (ComplexF32)
"""
function populateBuffer!(buffer::Vector{ComplexF32},bladeBuffer::Vector{Int16},index,burst_size)
    for n ∈ 1 : burst_size 
        buffer[index*burst_size + n] = Float32.(bladeBuffer[2(n-1)+1]) + 1im*Float32.(bladeBuffer[2(n-1)+2])
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

""" Destroy and safely release bladeRF object 
"""
function close(radio::BladeRFBinding)
    if radio.released == false 
        # Deactive radio module 
        status = bladerf_enable_module(radio.radio[], BLADERF_RX, false);
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


end
