module AbstractSDRs

# --- Define core module definitions 
using Libdl 
using Printf
using Sockets 
using Reexport

# --- 
@reexport using UHDBindings
# --- Specific UHD related functions 
export UHDBinding
export openUHD

# --- Create and load module to ilot E310 devices 
# To control this device we create a pure Socket based system 
# for which the AbstractSDRs package will help to bind the utils 
include("Host.jl");
@reexport using .Host
# --- Specific E310 related functions 
export UHDOverNetwork;
export openE310;


# --- Common framework functions 
# Closing resources call
export close;
# recv call 
recv(obj::UHDOverNetwork,tul...) = Host.recv(obj,tul...);
recv(obj::UHDBinding,tul...) = UHDBindings.recv(obj,tul...);
export recv;
# recv! call 
recv!(sig,obj::UHDOverNetwork,tul...) = Host.recv!(sig,obj,tul...);
recv!(sig,obj::UHDBinding,tul...) = UHDBindings.recv!(sig,obj,tul...);
# Send call 
send(sig,obj::UHDOverNetwork,tul...) = Host.send(sig,obj,tul...);
send(sig,obj::UHDBinding,tul...) = UHDBindings.send(sig,obj,tul...);
export send
# Radio API 
updateCarrierFreq!(obj::UHDOverNetwork,tul...) = Host.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::UHDBinding,tul...) = UHDBindings.updateCarrierFreq!(obj,tul...);
export updateCarrierFreq!;
updateSamplingRate!(obj::UHDOverNetwork,tul...) = Host.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::UHDBinding,tul...) = UHDBindings.updateSamplingRate!(obj,tul...);
export updateSamplingRate!;
updateGain!(obj::UHDOverNetwork,tul...) = Host.updateGain!(obj,tul...);
updateGain!(obj::UHDBinding,tul...) = UHDBindings.updateGain!(obj,tul...);
export updateGain!;
getError(obj::UHDBinding) = UHDBindings.getError(obj);
getError(obj::UHDOverNetwork) = Host.getMD(obj)[3];
export getError;
getTimestamp(obj::UHDBinding) = UHDBindings.getTimestamp(obj);
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
    nameL = lowercase(name);
    if nameL == "uhd"
        suppKwargs = [:args];
        radio = openUHD(tul...;parseKeyword(key,suppKwargs)...);
    elseif (nameL == "uhdovernetwork" || nameL == "e310")
        suppKwargs = [:ip];
        radio = openUhdOverNetwork(tul...;parseKeyword(key,suppKwargs)...);
    else 
        @error "Unknown or unsupported SDR device";
    end
    return radio;
end
export openSDR;

end # module
