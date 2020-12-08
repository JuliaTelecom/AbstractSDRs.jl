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
export openUHD


# ----------------------------------------------------
# --- Socket E310
# ---------------------------------------------------- 
# --- Create and load module to pilot E310 devices 
# To control this device we create a pure Socket based system 
# for which the AbstractSDRs package will help to bind the utils 
include("Host.jl");
@reexport using .Host
# --- Specific E310 related functions 
export UHDOverNetwork;

# ----------------------------------------------------
# --- Simulation Radio 
# ---------------------------------------------------- 
# --- Create and module to emulate a radio device without any actual radio connected
include("RadioSims.jl");
@reexport using .RadioSims
# --- Specific simulation related function 
export updatePacketSize!;
export RadioSim;

# ----------------------------------------------------
# --- Setting all methods using dispatch
# ---------------------------------------------------- 
# --- Common framework functions 
# Closing resources call
export close;
# recv call 
recv(obj::UHDOverNetwork,tul...) = Host.recv(obj,tul...);
recv(obj::UHDBinding,tul...) = UHDBindings.recv(obj,tul...);
recv(obj::RadioSim,tul...) = RadioSims.recv(obj,tul...);
export recv;
# recv! call 
recv!(sig,obj::UHDOverNetwork,tul...) = Host.recv!(sig,obj,tul...);
recv!(sig,obj::UHDBinding,tul...) = UHDBindings.recv!(sig,obj,tul...);
recv!(sig,obj::RadioSim,tul...) = RadioSims.recv!(sig,obj,tul...);
# Send call 
send(sig,obj::UHDOverNetwork,tul...;kwarg...) = Host.send(sig,obj,tul...;kwarg...);
send(sig,obj::UHDBinding,tul...) = UHDBindings.send(sig,obj,tul...);
send(sig,obj::RadioSim,tul...) = RadioSims.send(sig,obj,tul...);
export send
# Radio API 
updateCarrierFreq!(obj::UHDOverNetwork,tul...) = Host.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::UHDBinding,tul...) = UHDBindings.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::RadioSim,tul...) = RadioSims.updateCarrierFreq!(obj,tul...);
export updateCarrierFreq!;
updateSamplingRate!(obj::UHDOverNetwork,tul...) = Host.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::UHDBinding,tul...) = UHDBindings.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::RadioSim,tul...) = RadioSims.updateSamplingRate!(obj,tul...);
export updateSamplingRate!;
updateGain!(obj::UHDOverNetwork,tul...) = Host.updateGain!(obj,tul...);
updateGain!(obj::UHDBinding,tul...) = UHDBindings.updateGain!(obj,tul...);
updateGain!(obj::RadioSim,tul...) = RadioSims.updateGain!(obj,tul...);
export updateGain!;
getError(obj::UHDBinding) = UHDBindings.getError(obj);
getError(obj::RadioSim) = RadioSims.getError(obj);
getError(obj::UHDOverNetwork) = Host.getMD(obj)[3];
export getError;
getTimestamp(obj::UHDBinding) = UHDBindings.getTimestamp(obj);
getTimestamp(obj::RadioSim) = RadioSims.getTimestamp(obj);
getTimestamp(obj::UHDOverNetwork) = Host.getMD(obj)[1:2];


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


function openSDR(name,tul...;key...)
    @warn "Use symbol instead of string for radio identification"
    nameL = lowercase(name);
    if nameL == "uhd"
        suppKwargs = [:args];
        radio = openUHD(tul...;parseKeyword(key,suppKwargs)...);
    elseif (nameL == "uhdovernetwork" || nameL == "e310")
        suppKwargs = [:addr];
        radio = openUhdOverNetwork(tul...;parseKeyword(key,suppKwargs)...);
    else 
        @error "Unknown or unsupported SDR device";
    end
    return radio;
end
function openSDR(name::Symbol,tul...;key...)
    if name == :uhd
        suppKwargs = [:args];
        radio = openUHD(tul...;parseKeyword(key,suppKwargs)...);
    elseif (name == :uhdovernetwork || name == :e310)
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
