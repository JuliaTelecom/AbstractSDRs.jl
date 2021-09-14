module RadioSims
using Printf


# --- Print radio config
include("../Printing.jl");
using .Printing;

# Methods extension 
import Base:close;


# Symbols exportation 
export openRadioSim;
export updateCarrierFreq!;
export updateSamplingRate!;
export updateGain!; 
export updatePacketSize!;
export updateBuffer!;
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
    circularBuffer::Vector{Complex{Cfloat}};
    pointerBuffer::Int;
    buffer::Vector{Complex{Cfloat}};
    sleepVal::Cint;
    scaleSleep::Float64;
    doCirc::UInt8;
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

" Fill the output buffer with inputBuffer samples 
If lenght(outputBuffer) < length(inputBuffer) ==> truncate inputBuffer 
If lenght(outputBuffer) = length(inputBuffer) ==> fill with inputBuffer 
If lenght(outputBuffer) > length(inputBuffer) ==> repeat  inputBuffer 
It returns the pointer position of inputBuffer (position of last filled data, modulo inputBuffer size)
"
function circularFill!(outputBuffer,inputBuffer)
    sO = length(outputBuffer);
    sI = length(inputBuffer); 
    if sO ≤ sI 
        # ----------------------------------------------------
        # --- Buffer fill 
        # ---------------------------------------------------- 
        @inbounds @simd for n ∈ 1 : sO 
            outputBuffer[n] = inputBuffer[n];
        end
        return mod(sO,sI);
    else 
        # ----------------------------------------------------
        # --- Several rotation to do  
        # ---------------------------------------------------- 
        nbSeg = sO ÷ sI; 
        rest  = sO - sI*nbSeg;
        pos   = 0;
        @inbounds @simd for p ∈ 1 : nbSeg 
            offS = (p-1)*sI;
            for n ∈ 1 : sI 
                outputBuffer[offS + n] = inputBuffer[n];
            end
        end
        @inbounds @simd for n ∈ 1 : rest 
            outputBuffer[n] = inputBuffer[n];
        end
        return rest;
    end
end 

function openRadioSim(carrierFreq,samplingRate,gain;antenna="RX2",packetSize=-1,scaleSleep=1/1.60,buffer=nothing)
    # ----------------------------------------------------
    # --- Create the runtime structures
    # ---------------------------------------------------- 
    # --- Create the Rx wrapper 
    if buffer === nothing
        # --- Define packet size 
        (packetSize == -1 ) && (packetSize = 1024)
        # --- Define random buffer 
        buffer = randn(Complex{Cfloat},packetSize);
        circularBuffer = buffer;
        doCirc = false;
    else
        (packetSize == -1 ) && (packetSize = length(buffer))
        #@assert packetSize ≤ length(buffer) "Packet size should be ≤ to the given circular buffer"; # TODO handle repeat system if not
        if length(buffer) == packetSize
            doCirc = false;
        else
            # We will emulate a circular buffer
            doCirc= true;
        end
        circularBuffer = buffer;
        buffer = zeros(Complex{Cfloat},packetSize);
        circularFill!(buffer,circularBuffer);
        # We populate 
    end
    sleepVal = Cint(0);
    radioSimRxWrapper = RadioSimRxWrapper(circularBuffer,0,buffer,sleepVal,scaleSleep,doCirc);
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
    # (sleepVal == 0) && @warn "Sleep val is 0 => rate may be affected";
    radio.rx.radioSim.sleepVal = 0#sleepVal;
    radio.tx.radioSim.sleepVal = 0#sleepVal;
    # --- Update the sampling rate flag of the radio 
    radio.rx.samplingRate = samplingRate;
    radio.tx.samplingRate = samplingRate;
    # --- Return the rate
    return samplingRate;
end


function Base.print(rx::RadioSimRx);
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",rx.carrierFreq/1e6,rx.samplingRate/1e6,rx.gain);
    @inforx "Current Simulated Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(tx::RadioSimTx);
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",tx.carrierFreq/1e6,tx.samplingRate/1e6,tx.gain);
    @inforx "Current Simulated Radio Configuration in Rx mode\n$strF"; 
end
function Base.print(radio::RadioSim)
    print(radio.rx);
    print(radio.tx);
end

function recv(radio::RadioSim,packetSize)
    sig = zeros(Complex{Cfloat},packetSize);
    recv!(sig,radio);
    return sig;
end

function recv!(sig::Vector{Complex{Cfloat}},radio::RadioSim)
    # @assert length(sig) == radio.rx.packetSize;
    packetSize = length(sig);
    if radio.rx.radioSim.doCirc == false 
        # ----------------------------------------------------
        # --- Single shot output based in buffer field
        # ---------------------------------------------------- 
        if packetSize ≤ radio.rx.packetSize 
            # --- Everything is fine => Emulate radio time 
            # usleep(radio.rx);
            # --- Return the previsouly stored buffer
            sig .= radio.rx.radioSim.buffer[1:packetSize];
        else 
            @warn "Need additionnal processing as required buffer is larger than the one in memory. Please consider to enlarge the radio packet size using updatePacketSize!";
            # --- We want larger size than stored in the object, not a good idea
            nbSeg = 1 + packetSize ÷ radio.rx.packetSize;
            newBuff = repeat(radio.rx.radioSim.buffer,nbSeg);
            # --- Everything is fine => Emulate radio time 
            # usleep(radio.rx);
            # 
            sig .= newBuff[1:packetSize];
        end
    else 
        # ----------------------------------------------------
        # --- Circular buffer emulation
        # ---------------------------------------------------- 
        # --- Everything is fine => Emulate radio time 
        mP = length(radio.rx.radioSim.circularBuffer);
        if packetSize ≤ mP
            # --- We take only a part of the circular buffer, and we updat the pointer
            # usleep(radio.rx);
            # Copy circular buffer part in working buffer 
            radio.rx.radioSim.pointerBuffer
            for n ∈ 1 : packetSize 
                pos = 1 + mod(radio.rx.radioSim.pointerBuffer + n - 1,length(radio.rx.radioSim.circularBuffer));
                sig[n] = radio.rx.radioSim.circularBuffer[pos];
            end
            # sig .= radio.rx.radioSim.circularBuffer[radio.rx.radioSim.pointerBuffer .+ 1:packetSize];
            # Update circularBuffer pointer position 
            radio.rx.radioSim.pointerBuffer += packetSize; 
            # Circular buffer update (modulo)
            radio.rx.radioSim.pointerBuffer = mod(radio.rx.radioSim.pointerBuffer,length(radio.rx.radioSim.circularBuffer));
        else
            # --- We ask for more than the circular buffer, so repeat several time the circular buffer. 
            # Number of time we repeat 
            nbSeg = 1 + packetSize ÷ mP;
            # Last chunk of data 
            rest = nbSeg * mP - packetSize;
            # We need to repeat the circular buffer but not starting at first index. We use the pointer in memory 
            cB = circshift(radio.rx.radioSim.circularBuffer,radio.rx.radioSim.pointerBuffer);
            # Filling input buffer
            rest = circularFill!(sig,cB);
            # --- End of filled signal is next beginning
            radio.rx.radioSim.pointerBuffer = rest;
        end
   end
    return packetSize;
end

function send(radio::RadioSim,sig::Vector{Complex{Cfloat}},flag::Bool=false)
    while(flag)
        # usleep(radio.tx);
    end
end

function updatePacketSize!(radio,packetSize)
    # --- Create a new buffer 
    buffer = randn(Complex{Cfloat},packetSize);
    # --- Update structure 
    radio.rx.radioSimRxWrapper.buffer =  buffer;
end
function updateBuffer!(radio,buffer) 
    radio.rx.radioSimRxWrapper.buffer =  buffer;
    radio.rx.radioSimRxWrapper.circularBuffer =  buffer;
    radio.rx.radioSimRxWrapper.pointerBuffer = 0;
end

function Base.close(radio::RadioSim)
    radio.rx.released = true
    radio.tx.released = true
end

function getError(radio::RadioSim)
    return nothing;
end

function getTimeStamp(radio::RadioSim)
    return time();
end
end
