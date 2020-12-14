module AbstractSDRs

# --- Define core module definitions 
using Libdl 
using Printf
using Sockets 
using Reexport

# ----------------------------------------------------
# --- UHD Bindings 
# ---------------------------------------------------- 
# --- 
@reexport using UHDBindings
# --- Specific UHD related functions 
export UHDBinding


# ----------------------------------------------------
# --- Socket System
# ---------------------------------------------------- 
# --- Create and load module to pilot E310 devices 
# To control this device we create a pure Socket based system 
# for which the AbstractSDRs package will help to bind the utils 
include("SDROverNetworks.jl");
@reexport using .SDROverNetworks
# --- Specific E310 related functions 
export SDROverNetwork;

# ----------------------------------------------------
# --- Simulation Radio 
# ---------------------------------------------------- 
# --- Create and module to emulate a radio device without any actual radio connected
include("RadioSims.jl");
@reexport using .RadioSims
# --- Specific simulation related function 
export updatePacketSize!;
export updateBuffer!;
export RadioSim;

# ----------------------------------------------------
# --- Setting all methods using dispatch
# ---------------------------------------------------- 
# --- Common framework functions 
# Closing resources call
""" 
Close the SDR device and release all associated objects
# --- Syntax 
close(radio)
# --- Input parameters 
- radio : SDR device
# --- Output parameters 
- []
"""
export close;
# recv call 
"""
Receive nbSamples from the SDR and fill them in the output buffer. The buffer format depends on the SDR backend
--- Syntax
- buffer = recv(radio, nbSamples)
# --- Input parameters
- radio : SDR object 
- nbSamples : Desired number of samples 
# --- Output parameters
- buffer : Output buffer from the radio filled with nbSamples samples
"""
recv(obj::SDROverNetwork,tul...) = SDROverNetwork.recv(obj,tul...);
recv(obj::UHDBinding,tul...) = UHDBindings.recv(obj,tul...);
recv(obj::RadioSim,tul...) = RadioSims.recv(obj,tul...);
export recv;
 
# recv! call 
"""
Receive from the SDR and fill them in the input buffer.
--- Syntax
- nbSamples = recv!(sig,radio);
# --- Input parameters
- sig : Buffer to be filled
- radio : SDR device
# --- Output parameters
- nbSamples : Number of samples filled 
"""
recv!(sig,obj::SDROverNetwork,tul...) = SDROverNetwork.recv!(sig,obj,tul...);
recv!(sig,obj::UHDBinding,tul...) = UHDBindings.recv!(sig,obj,tul...);
recv!(sig,obj::RadioSim,tul...) = RadioSims.recv!(sig,obj,tul...);


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

send(sig,obj::SDROverNetwork,tul...;kwarg...) = SDROverNetwork.send(sig,obj,tul...;kwarg...);
send(sig,obj::UHDBinding,tul...) = UHDBindings.send(sig,obj,tul...);
send(sig,obj::RadioSim,tul...) = RadioSims.send(sig,obj,tul...);
export send

# Radio API 
updateCarrierFreq!(obj::SDROverNetwork,tul...) = SDROverNetwork.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::UHDBinding,tul...) = UHDBindings.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::RadioSim,tul...) = RadioSims.updateCarrierFreq!(obj,tul...);
export updateCarrierFreq!;

""" 
Update sampling rate of current radio device, and update radio object with the new obtained sampling frequency. 
# --- Syntax 
updateSamplingRate!(radio,samplingRate)
# --- Input parameters 
- radio	  : SDR device
- samplingRate	: New desired sampling rate 
# --- Output parameters 
- 
"""
updateSamplingRate!(obj::SDROverNetwork,tul...) = SDROverNetwork.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::UHDBinding,tul...) = UHDBindings.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::RadioSim,tul...) = RadioSims.updateSamplingRate!(obj,tul...);
export updateSamplingRate!;

""" 
Update gain of current radio device, and update radio object with the new obtained gain. 
If the input is a [UHDRx] or a [UHDTx] object, it updates only the Rx or Tx gain   
# --- Syntax 
updateGain!(radio,gain)
# --- Input parameters 
- radio	  : SDR device
- gain	: New desired gain 
# --- Output parameters 
- 
"""
updateGain!(obj::SDROverNetwork,tul...) = SDROverNetwork.updateGain!(obj,tul...);
updateGain!(obj::UHDBinding,tul...) = UHDBindings.updateGain!(obj,tul...);
updateGain!(obj::RadioSim,tul...) = RadioSims.updateGain!(obj,tul...);
export updateGain!;
getError(obj::UHDBinding) = UHDBindings.getError(obj);
getError(obj::RadioSim) = RadioSims.getError(obj);
getError(obj::SDROverNetwork) = SDROverNetwork.getMD(obj)[3];


export getError;
getTimestamp(obj::UHDBinding) = UHDBindings.getTimestamp(obj);
getTimestamp(obj::RadioSim) = RadioSims.getTimestamp(obj);
getTimestamp(obj::SDROverNetwork) = SDROverNetwork.getMD(obj)[1:2];


# --- Container for Radio use 
# We will have functions from different origin and different supported keywords 
# This function parse the input keywords and returns the ones supported by the function, listed in iteration
function parseKeyword(kwargs,iteration)
    # We populate a new dictionnary based on the input keywords and the supported ones 
    # In order not to create keywords that are not supported (i.e leaving the default value)
    # we only evaluate the keywords defined both in the 2 dictionnaries 
    # This means that the default fallback should never happen
    kwargs = Dict(key=>get(kwargs,key,0) for key in intersect(iteration,keys(kwargs)))
    return kwargs
end


"""
Returns an array of symbol which lists the supported SDR backends
--- Syntax
l = getSupportedSDR()
# --- Input parameters
-
# --- Output parameters
- l : Array of symbols of supported SDRs
"""
function getSupportedSDR()
    return [:uhd;:sdr_over_network;:radiosim;:pluto];
end

"""
Open a Software Defined Radio of backend 'type', tune accordingly based on input parameters and use the supported keywords.
It returns a radio object, depending on the type of SDR that can be used with all AbstractSDRs supported functions
--- Syntax
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
    else 
        @error "Unknown or unsupported SDR device";
    end
    return radio;
end
export openSDR;

end # module
