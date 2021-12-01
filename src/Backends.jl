# ---------------------------------
# --- UHD Bindings
# ----------------------------------------------------
# Backend to pilot USRP with UHD lib
@reexport using UHDBindings
# --- Specific UHD related functions
# We export the UHD structure 
export UHDBinding

# ----------------------------------------------------
# --- Adalm Pluto managment 
# ----------------------------------------------------
# Backend for Adalm Pluto 
@reexport using AdalmPluto
# --- Specific Pluto exportation 
# We export the Adalm Pluto structure and the specific updateGainMode function
export AdalmPluto;
export updateGainMode!;


# ----------------------------------------------------
# --- RTL-SDR bindings
# ----------------------------------------------------
include("Backends/RTLSDR/RTLSDRBindings.jl");
@reexport using .RTLSDRBindings
export RTLSDRBinding

# ----------------------------------------------------
# --- Socket System
# ----------------------------------------------------
# --- Create and load module to pilot E310 devices
# To control this device we create a pure Socket based system
# for which the AbstractSDRs package will help to bind the utils
# Have a look on minimalTransceiver.jl for the code to be ran on E310
include("Backends/SDROverNetworks.jl");
@reexport using .SDROverNetworks
# --- Specific E310 related functions
export SDROverNetwork;

# ----------------------------------------------------
# --- Simulation Radio
# ----------------------------------------------------
# --- Create and module to emulate a radio device without any actual radio connected
include("Backends/RadioSims.jl");
@reexport using .RadioSims
# --- Specific simulation related function
export updatePacketSize!;
export updateBuffer!;
export RadioSim;

# ----------------------------------------------------
# --- Define common radio type 
# ---------------------------------------------------- 
# We define an Union type that gathers all SDR backends 
# This type will be used as default fallback methods to handle 2 things 
# - In case of functions not supported in the given backend to obtain a predictible (and non error) behaviour 
# - To simplify access to similar backends fields
AbstractSDR = Union{RadioSim,UHDBinding,PlutoSDR,SDROverNetwork,RTLSDRBinding}


