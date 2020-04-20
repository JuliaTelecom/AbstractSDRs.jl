module AbstractSDRs

# --- Define core module definitions 
using Libdl 
using Printf
using Sockets 
using Reexport

# --- 
@reexport using UHDBindings
# --- Specific UHD related functions 
export UHDTx
export UHDRx
export openUHDTx;
export openUHDRx
export openUHD;

# --- Create and load module to ilot E310 devices 
# To control this device we create a pure Socket based system 
# for which the AbstractSDRs package will help to bind the utils 
include("HostE310.jl");
@reexport using .HostE310
# --- Specific E310 related functions 
export StructE310;
export openE310;
export openE310Rx;


# --- Common framework functions 
# Closing resources call
export close;
# recv call 
recv(obj::StructE310,tul...) = HostE310.recv(obj,tul...);
recv(obj::UHDRx,tul...) = UHD.recv(obj,tul...);
recv(obj::UHDTx,tul...) = UHD.recv(obj,tul...);
export recv;
# recv! call 
recv!(sig,obj::StructE310,tul...) = HostE310.recv!(sig,obj,tul...);
recv!(sig,obj::UHDRx,tul...) = UHD.recv!(sig,obj,tul...);
recv!(sig,obj::UHDTx,tul...) = UHD.recv!(sig,obj,tul...);
# Radio API 
updateCarrierFreq!(obj::StructE310,tul...) = HostE310.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::UHDRx,tul...) = UHD.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::UHDTx,tul...) = UHD.updateCarrierFreq!(obj,tul...);
export updateCarrierFreq!;
updateSamplingRate!(obj::StructE310,tul...) = HostE310.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::UHDRx,tul...) = UHD.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::UHDTx,tul...) = UHD.updateSamplingRate!(obj,tul...);
export updateSamplingRate!;
updateGain!(obj::StructE310,tul...) = HostE310.updateGain!(obj,tul...);
updateGain!(obj::UHDRx,tul...) = UHD.updateGain!(obj,tul...);
updateGain!(obj::UHDTx,tul...) = UHD.updateGain!(obj,tul...);
export updateGain!;
getError(obj::UHDTx) = UHD.getError(obj);
getError(obj::UHDRx) = UHD.getError(obj);
getError(obj::StructE310) = HostE310.getMD(obj)[3];
export getError;
getTimestamp(obj::UHDTx) = UHD.getTimestamp(obj);
getTimestamp(obj::UHDRx) = UHD.getTimestamp(obj);
getTimestamp(obj::StructE310) = HostE310.getMD(obj)[1:2];


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
    if nameL == "uhdrx"
        suppKwargs = [:args];
        radio = openUHD("Rx",tul...;parseKeyword(key,suppKwargs)...);
    elseif nameL == "uhdtx"
        suppKwargs = [:args];
        radio = openUHD("Tx",tul...;parseKeyword(key,suppKwargs)...);
    elseif nameL == "e310rx"
        suppKwargs = [:ip];
        radio = openE310Rx(tul...;parseKeyword(key,suppKwargs)...);
    else 
        @error "Unknown or unsupported SDR device";
    end
    return radio;
end
export openSDR;

end # module
