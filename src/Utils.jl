# ----------------------------------------------------
# --- Utils.jl
# ---------------------------------------------------- 
# We put here common usefull stuff for SDR managment 



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

# --- Conversion 
# Adalm Pluto structure is based on Int parameters, and AbstractSDRs use massively Float. We need to convert just before dispatching. As some parameter may be float (as gain) we should round before conversion. The following function does that.
_toInt(x) = Int(round(x));


