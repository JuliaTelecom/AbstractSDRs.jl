module RadioSims
using Printf


# --- Print radio config
include("Printing.jl");
using .Printing;

# Methods extension 
import Base:close;


# Symbols exportation 
export openRadioSim;
export close;
export updateCarrierFreq!;
export updateSamplingRate!;
export updateGain!; 
export updatePacketSize!;
export recv;
export recv!;
export send;
export print;
export getError
export getTimeStamp;
# 
export RadioSim;
# --- Main Rx structure 
mutable struct RadioSimRxWrapper
    buffer::Vector{Complex{Cfloat}};
    sleepVal::Cint;
    scaleSleep::Float64;
end;
mutable struct RadioSimRx
	radioSim::RadioSimRxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
	packetSize::Csize_t;
	released::Int;
end


# --- Main Tx structure 
mutable struct RadioSimTxWrapper
    sleepVal::Cint;
    scaleSleep::Float64;
end;
mutable struct RadioSimTx 
	radioSim::RadioSimTxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
	packetSize::Csize_t;
	released::Int;
end

# --- Complete structure 
mutable struct RadioSim
    radio::String;
    rx::RadioSimRx;
    tx::RadioSimTx;
end


usleep(usecs) = ccall(:usleep, Cint, (Cuint,), usecs);
usleep(rx::RadioSimRx) = usleep(rx.radioSim.sleepVal);
usleep(tx::RadioSimTx) = usleep(tx.radioSim.sleepVal);

function openRadioSim(carrierFreq,samplingRate,gain;antenna="RX2",packetSize=1024,scaleSleep=1/1.60)
    # ----------------------------------------------------
    # --- Create the runtime structures
    # ---------------------------------------------------- 
    # --- Create the Rx wrapper 
    buffer = randn(Complex{Cfloat},packetSize);
    sleepVal = Cint(0);
    radioSimRxWrapper = RadioSimRxWrapper(buffer,sleepVal,scaleSleep);
    rx = RadioSimRx(radioSimRxWrapper,carrierFreq,samplingRate,gain,antenna,packetSize,0);
    # --- Create the Tx Wrapper 
    radioSimTxWrapper = RadioSimTxWrapper(sleepVal,scaleSleep);
    tx = RadioSimTx(radioSimTxWrapper,carrierFreq,samplingRate,gain,antenna,packetSize,0);
    # ---- Create the complete Radio 
    radio = RadioSim("radioSim",rx,tx);
    # ----------------------------------------------------
    # --- Update the radio component
    # ---------------------------------------------------- 
    # --- We should update the sampling rate as it will set the appropriate sleeping duration associated top the emulation of rate
    updateSamplingRate!(radio,samplingRate);
    # --- Return the radio object 
    return radio;
end


function updateCarrierFreq!(radio::RadioSim,carrierFreq);
    radio.rx.carrierFreq = carrierFreq;
    radio.tx.carrierFreq = carrierFreq;
    return carrierFreq;
end


function updateGain!(radio::RadioSim,gain);
    radio.rx.gain = gain;
    radio.tx.gain = gain;
    return gain;
end

function updateSamplingRate!(radio::RadioSim,samplingRate);
    # --- We have to calculate the new sleeping value in μs
    sleepVal = Cint(floor( radio.rx.packetSize / samplingRate * radio.rx.radioSim.scaleSleep * 1e6));
    (sleepVal == 0) && @warn "Sleep val is 0 => rate may be affected";
    radio.rx.radioSim.sleepVal = sleepVal;
    radio.tx.radioSim.sleepVal = sleepVal;
    # --- Update the sampling rate flag of the radio 
    radio.rx.samplingRate = samplingRate;
    radio.tx.samplingRate = samplingRate;
    # --- Return the rate
    return samplingRate;
end


function Base.print(radio::RadioSim);
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",radio.rx.carrierFreq/1e6,radio.rx.samplingRate/1e6,radio.rx.gain);
    @inforx "Current Simulated Radio Configuration in Rx mode\n$strF"; 
end


function recv(radio::RadioSim,packetSize)
    if packetSize ≤ radio.rx.packetSize 
        # --- Everything is fine => Emulate radio time 
        usleep(radio.rx);
        # --- Return the previsouly stored buffer
        return @view radio.rx.radioSim.buffer[1:packetSize];
    else 
        @warn "Need additionnal processing as required buffer is larger than the one in memory. Please consider to enlarge the radio packet size using updatePacketSize!";
        # --- We want larger size than stored in the object, not a good idea
        nbSeg = 1 + packetSize ÷ radio.rx.packetSize;
        newBuff = repeat(radio.rx.radioSim.buffer,nbSeg);
        # --- Everything is fine => Emulate radio time 
        usleep(radio.rx);
        # 
        return @view newBuff[1:packetSize];
    end
end

function recv!(sig::Vector{Complex{Cfloat}},radio::RadioSim)
    packetSize = length(sig);
    if packetSize ≤ radio.rx.packetSize 
        # --- Everything is fine => Emulate radio time 
        usleep(radio.rx);
        # --- Return the previsouly stored buffer
        sig .= radio.rx.radioSim.buffer[1:packetSize];
    else 
        @warn "Need additionnal processing as required buffer is larger than the one in memory. Please consider to enlarge the radio packet size using updatePacketSize!";
        # --- We want larger size than stored in the object, not a good idea
        nbSeg = 1 + packetSize ÷ radio.rx.packetSize;
        newBuff = repeat(radio.rx.radioSimRxWrapper.buffer,nbSeg);
        # --- Everything is fine => Emulate radio time 
        usleep(radio.rx);
        # 
        sig .= newBuff[1:packetSize];
    end
    return packetSize;
end

function send(sig::Vector{Complex{Cfloat}},radio::RadioSim)
    usleep(radio.tx);
end

function updatePacketSize!(radio,packetSize)
    # --- Create a new buffer 
    buffer = randn(Complex{Cfloat},packetSize);
    # --- Update structure 
    radio.rx.radioSimRxWrapper.buffer =  buffer;
end


function Base.close(radio::RadioSim)
    radio = nothing;
end

function getError(radio::RadioSim)
    return nothing;
end

function getTimeStamp(radio::RadioSim)
    return time();
end
end
