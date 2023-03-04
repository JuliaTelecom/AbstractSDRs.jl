module RTLSDRBindings 

# --- Print radio config
include("../../Printing.jl");
using .Printing

# -- Loading driver bindings 
include("./LibRtlsdr.jl")
using  .LibRtlsdr

using Printf

# Methods extension 
import Base:close;

# Symbols exportation 
export openRTLSDR;
export updateCarrierFreq!;
export updateSamplingRate!;
export updateGain!; 
export recv;
export recv!;
export send;
export print;
export getError
export RTLSDRBinding;


# Utils to generate String containers 
""" 
Init an empty string of size n, filled with space. Usefull to have container to get string from UHD.
"""
initEmptyString(n) = String(ones(UInt8,n)*UInt8(32))
""" 
Retrict the big string used as log container to its usefull part 
"""
function truncate(s::String)
    indexes =  findfirst("\0",s)
    if isnothing(indexes)
        # No end of line, controls that it is not only whitespace 
        if length(unique(s)) == 1 
            # String is empty, abord
            sO = " "
        else 
            # Return the string as it is 
            s0 = s 
        end
    else 
        # Truncated output
        sO = s[1: indexes[1] - 1]
    end 
    return s
end

mutable struct RTLSDRRxWrapper
    buffer::Vector{UInt8}
end
# --- Main Rx structure 
mutable struct RTLSDRRx
    rtlsdr::RTLSDRRxWrapper
    carrierFreq::Float64
    samplingRate::Float64;
    gain::Union{Int,Float64}; 
    antenna::String;
    packetSize::Csize_t;
    released::Int;
end

# --- Main Tx structure 
mutable struct RTLSDRTx 
    carrierFreq::Float64
    samplingRate::Float64
    gain::Union{Int,Float64}
    antenna::String
    packetSize::Csize_t
    released::Int
end

# --- Complete structure 
mutable struct RTLSDRBinding
    radio::Ref{Ptr{rtlsdr_dev_t}}
    rx::RTLSDRRx
    tx::RTLSDRTx
end



function openRTLSDR(carrierFreq,samplingRate,gain;agc_mode=0,tuner_gain_mode=0)
    # --- Instantiate a new RTLSDR device 
    ptr_rtlsdr = Ref{Ptr{rtlsdr_dev_t}}()
    chan = 0
    rtlsdr_open(ptr_rtlsdr,chan)
    # --- Get the instantiate object 
    rtlsdr  = ptr_rtlsdr[]
    rtlsdr_reset_buffer(rtlsdr)
    # --- Configure it based on what we want 
    # Sampling rate (2MHz max ?)
    rtlsdr_set_sample_rate(rtlsdr,samplingRate)
    samplingRate = rtlsdr_get_sample_rate(rtlsdr)
    # Carrier freq 
    rtlsdr_set_center_freq(rtlsdr,carrierFreq)
    carrierFreq = rtlsdr_get_center_freq(rtlsdr)
    # Gain mode 
    rtlsdr_set_tuner_gain_mode(rtlsdr,tuner_gain_mode)
    rtlsdr_set_agc_mode(rtlsdr,agc_mode)
    # ----------------------------------------------------
    # --- Wrap all into a custom structure 
    # ----------------------------------------------------  
    # Instantiate a buffer to handle async receive. Size is arbritrary and will be modified afterwards 
    buffer = zeros(UInt8,512)
    rtlsdrRx = RTLSDRRxWrapper(buffer)
    rx = RTLSDRRx(
                  rtlsdrRx,
                  carrierFreq,
                  samplingRate,
                  0,
                  "RX",
                  0,
                  0
                 );
    tx = RTLSDRTx(
                  carrierFreq,
                  samplingRate,
                  0,
                  "TX",
                  0,
                  0
                 );    
    radio = RTLSDRBinding(
                          ptr_rtlsdr,
                          rx,
                          tx
    )
    return radio
end

function updateCarrierFreq!(radio::RTLSDRBinding,carrierFreq)
    # --- Set the carrier frequency 
    rtlsdr_set_center_freq(radio.radio[],carrierFreq)
    # --- Get the carrier frequency 
    carrierFreq = rtlsdr_get_center_freq(radio.radio[])
    # --- Update structure
    radio.rx.carrierFreq = carrierFreq;
    radio.tx.carrierFreq = carrierFreq;
    return carrierFreq;
end
function updateSamplingRate!(radio,samplingRate)
    # --- Set the sampling rate 
    rtlsdr_set_sample_rate(radio.radio[],samplingRate)
    # --- Get the sampling rate 
    samplingRate = rtlsdr_get_sample_rate(radio.radio[])
    # --- Update Fields
    radio.rx.samplingRate = samplingRate;
    radio.tx.samplingRate = samplingRate;
    return samplingRate
end
function updateGain!(radio,gain)
    # @warn "Analog gain update is not supported for RTLSDR";
end


function Base.print(rx::RTLSDRRx);
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n",rx.carrierFreq/1e6,rx.samplingRate/1e6)
    @inforx "Current RTL-SDR Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(tx::RTLSDRTx);
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n",tx.carrierFreq/1e6,tx.samplingRate/1e6)
    @infotx "Current RTL-SDR Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(radio::RTLSDRBinding)
    print(radio.rx);
    print(radio.tx);
end


function recv!(sig::Vector{ComplexF32},radio::RTLSDRBinding)
    nbSamples = length(sig)
    # --- Instantiation of UInt8 buffer 
    if length(radio.rx.rtlsdr.buffer) !== 2*nbSamples 
        # We need to redimension the size of the receive buffer 
        buffer = zeros(UInt8,nbSamples * 2)
        radio.rx.rtlsdr.buffer = buffer
    end
    pointerSamples   = Ref{Cint}(0)
    # --- Call the receive method 
    ptr = pointer(radio.rx.rtlsdr.buffer,1)
    rtlsdr_read_sync(radio.radio[],ptr,nbSamples*2,pointerSamples)
    # --- Get the number of received complex symbols
    nbElem = pointerSamples[] ÷ 2
    # --- From Bytes to complex 
    byteToComplex!(sig,radio.rx.rtlsdr.buffer)
    return nbElem
end


function recv(radio::RTLSDRBinding,nbSamples)
    sig = zeros(ComplexF32,nbSamples)
    nbElem = recv!(sig,radio)
    (nbElem == 0) && @warnrx "No received samples !"
    return sig
end




""" Transform the input buffer of UInt8 into a complexF32 vector
"""
function byteToComplex!(sig::Vector{ComplexF32},buff::Vector{UInt8})
    nbS = length(sig)
    @assert (length(buff) == 2nbS) "Complex buffer size should be 2 times lower (here $(length(sig))  than input Buffersize (here $(length(buff))"
    @inbounds @simd  for n ∈ 1 : nbS
        sig[n] = _btoc(buff[2(n-1)+1]) + 1im*_btoc(buff[2(n-1)+2])
    end
end 
function byteToComplex(buff::Vector{UInt8})
    N = length(buff)
    nbS = N ÷ 2 
    sig = zeros(ComplexF32,nbS)
    byteToComplex!(sig,buff)
end

""" Byte to float conversion 
"""
function _btoc(in::UInt8)
    return in / 128 -1 
end

function close(radio::RTLSDRBinding)
    rtlsdr_close(radio.radio[])
    radio.rx.released = 1;
    radio.tx.released = 1;
    @info "RTL-SDR device is now close"
end

function send(sig::Vector{Complex{Cfloat}},radio::RTLSDRBinding)
    @warntx "Unsupported send method for RTLSDR"; 
end




function scan()
    # --- Using counting method to get the nbumber of devioes 
    nE = LibRtlsdr.rtlsdr_get_device_count()
    if nE > 0 
        # Found a RTL SDR dongle 
        println("Found $nE RTL-SDR dongle")
        # manufact = initEmptyString(200)
        # product = initEmptyString(200)
        # serial = initEmptyString(200)
        # radio = openRTLSDR(800e6,1e6,20)
        # rtlsdr_get_usb_strings(radio.radio[],manufact,product,serial)
        # (!isempty(manufact)) && (println("Manufact = $(truncate(manufact))"))
        # (!isempty(product)) && (println("Product  = $(truncate(product))"))
        # (!isempty(serial)) && (println("Serial   = $(truncate(serial))"))
        # close(radio)
    end
    return nE
end




function getError(radio::RTLSDRBinding)
    return 0
end
function getMD(radio::RTLSDRBinding)
    return 0
end
end
