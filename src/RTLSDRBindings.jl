module RTLSDRBindings 

# --- Print radio config
include("Printing.jl");
using .Printing

using RTLSDR 

# --- Main Rx structure 
mutable struct RTLSDRRxWrapper
end;
mutable struct RTLSDRRx
	rtlsdrrx::RTLSDRRxWrapper
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
	packetSize::Csize_t;
	released::Int;
end


# --- Main Tx structure 
mutable struct RTLSDRTxWrapper
end;
mutable struct RTLSDRTx 
	rtlsdrrxwrapper::RTLSDRTxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
	packetSize::Csize_t;
	released::Int;
end

# --- Complete structure 
mutable struct RTLSDRBinding
    radio::RtlSdr;
    rx::RadioSimRx;
    tx::RadioSimTx;
end



function openRTLSDR(carrierFreq,samplingRate,gain;agc_mode=0,tuner_gain_mode=0)
    # --- Open a new instance of RTLSDR 
    rtlsdr = RtlSdr();
    # --- Configure it based on what we want 
    set_rate(rtlsdr,samplingRate);
    set_freq(rtlsdr,carrierFreq);
    set_tuner_gain_mode(rtlsdr,tuner_gain_mode);
    set_agc_mode(rtlsdr,agc_mode);
    # ----------------------------------------------------
    # --- Wrap all into a custom structure 
    # ----------------------------------------------------  
    rxWrapper = RTLSDRRxWrapper();
    rx = RTLSDRRx(
        rxWrapper,
        carrierFreq,
        samplingRate,
        0,
        "RX",
        0,
        0
    );
    txWrapper = RTLSDRTxWrapper();
    tx = RTLSDRRx(
        txWrapper,
        carrierFreq,
        samplingRate,
        0,
        "TX",
        0,
        0
    );    
    radio = RTLSDRBinding(
        rtlsdr,
        rx,
        tx
    )
    return radio
end

function updateCarrierFreq!(radio::RTLSDRBinding,carrierFreq)
    set_freq(radio.radio,carrierFreq);
    radio.rx.carrierFreq = carrierFreq;
    radio.tx.carrierFreq = carrierFreq;
    return carrierFreq;
end
function updateSamplingRate!(radio,samplingRate)
    set_rate(radio.radio,samplingRate);
    radio.rx.samplingRate = samplingRate;
    radio.tx.samplingRate = samplingRate;
    return samplingRate
end
function updateGain!(radio,gain)
    @warning "Analog gain update is not supported for RTLSDR";
end




function Base.print(rx::RTLSDRRx);
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",rx.carrierFreq/1e6,rx.samplingRate/1e6,rx.gain);
    @inforx "Current Simulated Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(tx::RTLSDRTx);
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",tx.carrierFreq/1e6,tx.samplingRate/1e6,tx.gain);
    @inforx "Current Simulated Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(radio::RTLSDRBinding)
    print(radio.rx);
    print(radio.tx);
end

function recv(radio::RTLSDRBinding,nbSamples)
    return read_samples(radio.radio,nbSamples);
end
function recv!(sig::Vector{Complex{Cfloat}},radio::RTLSDRBinding)
    nS = length(sig);
    sig .= recv(radio,nS);
end


function send(sig::Vector{Complex{Cfloat}},radio::RTLSDRBinding)
   @warntx "Unsupported send method for RTLSDR"; 
end


function getError(radio::RTLSDRBinding)
    return 0
end
function getMD(radio::RTLSDRBinding)
    return 0
end
end