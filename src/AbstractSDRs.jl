module AbstractSDRs

# --- Define core module definitions
using Libdl
using Printf
using Sockets
using Reexport
using RTLSDR

import Base:close;

# ----------------------------------------------------
# --- Get Supported backends
# ---------------------------------------------------- 
"""
Returns an array of symbol which lists the supported SDR backends
# --- Syntax
l = getSupportedSDR()
# --- Input parameters
-
# --- Output parameters
- l : Array of symbols of supported SDRs
"""
function getSupportedSDRs()
    return [:uhd;:sdr_over_network;:radiosim;:pluto;:rtlsdr];
end
export getSupportedSDRs



# ----------------------------------------------------
# --- Utils 
# ---------------------------------------------------- 
# Common generic functions and glue required for the package 
# Nothing strictly related to radio here, only common stuff
include("Utils.jl")

# ----------------------------------------------------
# --- Backends 
# ---------------------------------------------------- 
# --- Load backend 
include("Backends.jl")

# ----------------------------------------------------
# --- Scanning 
# ---------------------------------------------------- 
include("Scan.jl")
export scan

# ----------------------------------------------------
# --- Radio configuration (update radio parameters)
# ---------------------------------------------------- 
include("Mutators.jl")
export updateCarrierFreq!
export updateSamplingRate!
export updateGain!
export updateGainMode!

# ----------------------------------------------------
# --- Assessors (get radio parameters)
# ---------------------------------------------------- 
include("Assessors.jl")
export getError 
export getTimestamp 
export getSamplingRate 
export getCarrierFreq 
export getGain 
export isClosed 
export getBufferSize


#----------------------------------------------------
# --- Common API
# ---------------------------------------------------- 

# recv call
"""
Receive nbSamples from the SDR and fill them in the output buffer. The buffer format depends on the SDR backend
# --- Syntax
- buffer = recv(radio, nbSamples)
# --- Input parameters
- radio : SDR object
- nbSamples : Desired number of samples
# --- Output parameters
- buffer : Output buffer from the radio filled with nbSamples samples
"""
recv(obj::SDROverNetwork,tul...) = SDROverNetworks.recv(obj,tul...);
recv(obj::UHDBinding,tul...) = UHDBindings.recv(obj,tul...);
recv(obj::RadioSim,tul...) = RadioSims.recv(obj,tul...);
recv(obj::RTLSDRBinding,tul...) = RTLSDRBindings.recv(obj,tul...);
recv(obj::PlutoSDR,tul...) = AdalmPluto.recv(obj,tul...);
export recv;

# recv! call
"""
Receive from the SDR and fill them in the input buffer.
# --- Syntax
- nbSamples = recv!(sig,radio);
# --- Input parameters
- sig : Buffer to be filled
- radio : SDR device
# --- Output parameters
- nbSamples : Number of samples filled
"""
recv!(sig,obj::SDROverNetwork,tul...) = SDROverNetworks.recv!(sig,obj,tul...);
recv!(sig,obj::UHDBinding,tul...) = UHDBindings.recv!(sig,obj,tul...);
recv!(sig,obj::RadioSim,tul...) = RadioSims.recv!(sig,obj,tul...);
recv!(sig,obj::RTLSDRBinding,tul...) = RTLSDRBindings.recv!(sig,obj,tul...);
recv!(sig,obj::PlutoSDR,tul...) = AdalmPluto.recv!(sig,obj,tul...);


# Send call
"""
Send a buffer though the radio device. It is possible to force a cyclic buffer send (the radio uninterruply send the same buffer) by setting the cyclic parameter to true
# --- Syntax
send(radio,buffer,cyclic=false)
# --- Input parameters
- radio	  	: SDR device
- buffer 	: Buffer to be send
- cyclic 	: Send same buffer multiple times (default false) [Bool]
# --- Output parameters
- nbEch 	: Number of samples effectively send [Csize_t]. It corresponds to the number of complex samples sent.
"""

send(obj::SDROverNetwork,sig,tul...;kwarg...) = SDROverNetworks.send(obj,sig,tul...;kwarg...);
send(obj::UHDBinding,sig,tul...) = UHDBindings.send(obj,sig,tul...)
send(obj::RadioSim,sig,tul...) = RadioSims.send(obj,sig,tul...)
send(obj::RTLSDRBinding,sig,tul...) = RTLSDRBindings.send(obj,sig,tul...)
send(obj::PlutoSDR,sig,tul...;kwarg...) = AdalmPluto.send(obj,sig,tul...;parseKeyword(kwarg,[:use_internal_buffer]))
export send


"""
Open a Software Defined Radio of backend 'type', tune accordingly based on input parameters and use the supported keywords.
It returns a radio object, depending on the type of SDR that can be used with all AbstractSDRs supported functions
# --- Syntax
radio = openSDR(type,carrierFreq,samplingRate,gain,antenna;key)
# --- Input parameters
- type  : Desired SDR type. The different supported radio format can be obtained with getSupportedSDR();
- carrierFreq : Carrier frequency [Hz]
- samplingRate : Sampling frequency (Hz)
- gain : Analog Rx gain (dB)
# --- Output parameters
- radio : Defined SDR object
"""
function openSDR(name::Symbol,tul...;key...)
    if name == :uhd
        suppKwargs = [:args];
        radio = openUHD(tul...;parseKeyword(key,suppKwargs)...);
    elseif (name == :sdr_over_network || name == :e310)
        suppKwargs = [:addr];
        keyOut = parseKeyword(key,suppKwargs);
        if haskey(key,:args)
            # For UHDBindings IP address is set as args="addr=192.168.10.14". We want to support this
            # We look at args and find addr inside and extract the IP address. Then create a dict entry
            str = key[:args];
            ind = findfirst("addr",str)[1];
            # If addr flag is here, convert it into IP
            if ~isnothing(ind)
                # --- Getting end of parameter
                indV = findfirst(",",str[ind:end]);
                # --- If last parameters, get the compelte string
                (isnothing(indV)) ? indF = length(str) : indF = indV[1];;
                # --- Extract ip address
                ip = str[ind+5:indF];
                # --- Create a new input in dictionnary
                keyOut[:addr] = ip;
            end
        end
        radio = openUhdOverNetwork(tul...;keyOut...);
    elseif (name == :radiosim)
        suppKwargs = [:packetSize;:scaleSleep;:buffer];
        radio = openRadioSim(tul...;parseKeyword(key,suppKwargs)...);
    elseif name == :rtlsdr
        suppKwargs = [:agc_mode;:tuner_gain_mode]
        radio = openRTLSDR(tul...;parseKeyword(key,suppKwargs)...);
    elseif name == :pluto
        # --- List of supported keywords 
        suppKwargs = [:addr; :backend; :bufferSize; :bandwidth];
        # --- Managing Int argument 
        # In Pluto the config uses Int parameter, and we specify Float as the top APi of AbstractSDRs. We should convert this 
        # --- Opening radio device 
        radio = openPluto(_toInt.(tul)...; parseKeyword(key, suppKwargs)...);
    else
        @error "Unknown or unsupported SDR device. use getSupportedSDR() to list supported SDR backends";
    end
    return radio;
end
export openSDR;




end # module
