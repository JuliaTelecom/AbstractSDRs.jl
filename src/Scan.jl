# ----------------------------------------------------
# --- Find.jl
# ---------------------------------------------------- 
# Methods to scan for SDR devices, based on backend specifications or parameters 



""" 
Scan interface and returns the founded SDR 
# --- Syntax 
sdr = scan() 
sdr = scan(backend;key...)
# Input parameter 
If the function is called without parameters il will search for all avaliable backends such as UHDBindings and AdalmPluto. Otherwise the search will be limited to the desired backend 
The optionnal arguments are the one supported by UHDBindings and AdalmPluto. See `uhd_find_devices()` in UHDBindings and `scan` function in AdalmPluto 
# Keywords 
- args : String used in UHD backend to specify USRP IP address. Example: scan(:uhd;args="addr=192.168.10.16")
- backend : Sring used in Pluto backend to specify the interface used ("local", "xml", "ip", "usb")
"""
function scan(backend::Union{Nothing,Vector{Symbol}}=nothing;key...)
    # --- If call w/o argument we search for all potential backends 
    # Note that we can not search for SDROverNetwork, RadioSims and RTLSDR
    # TODO => Scan methods for RTLSDR ?
    if isnothing(backend)
        backend = [:uhd;:pluto]
    end 
    allStr = String[];
    for b in backend 
        if b == :uhd 
            println("----------------------------")
            println("--- Scan for UHD devices ---")
            println("----------------------------")
            # ----------------------------------------------------
            # --- UHD Find device call 
            # ---------------------------------------------------- 
            # --- Restrict keywords to uhd_find_devices 
            key = parseKeyword(key,[:args])
            # scan keyword is uhd_find_devices parameter so we should handle empty case 
            (isempty(key)) && (key[:args] = "")
            # --- Call scanner 
            e  = UHDBindings.uhd_find_devices(key[:args])
            # --- Return the direct IP address based on the str cal
            for eN in e 
                eM = eN[findfirst("_addr=",eN)[end] .+ (1:13)]
                push!(allStr,eM)
            end
        elseif b == :pluto 
            println("------------------------------")
            println("--- Scan for Pluto devices ---")
            println("------------------------------")
            # ----------------------------------------------------
            # --- Scan call 
            # ---------------------------------------------------- 
            # --- Restrict keywords to pluto 
            key = parseKeyword(key,[:backend])
            if (isempty(key)) 
                # By default we look for all available backends 
                backend = ["usb","local","ip","xml"]
            else 
                # Focus on given backend
                backend = [key[:backend]]
            end
            for b in backend 
                # --- Call scanner 
                e = AdalmPluto.scan(b)
                # --- Push in Vector of string 
                # AdalmPluto answer "" and this corresponds to nothing interessting. We push in the vector only if what we had was not empty
                (!isempty(e)) && (push!(allStr,e))
            end
        elseif b == :radiosim
            # ----------------------------------------------------
            # --- Radiosims backend
            # ---------------------------------------------------- 
            # No need to worry, we always have the simulated backend 
            # Returns an arbitrary String with description 
            println("------------------------------")
            println("--- Scan for RadioSims    ---")
            println("------------------------------")
            push!(allStr,"RadioSim  backend is always there !")
        end 
    end 
    return allStr
end
scan(backend::Symbol;key...) = scan([backend];key...)
