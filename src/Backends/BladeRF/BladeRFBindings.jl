module BladeRFBindings

# --- Print radio config
include("../../Printing.jl");
using .Printing

# -- Loading driver bindings 
include("./LibBladeRF.jl")
using  .LibBladeRF

using Printf

# Methods extension 
import Base:close;


# Exports 
export openBladeRF

mutable struct BladeRFRxWrapper
    buffer::Vector{UInt8}
end
mutable struct BladeRFTxWrapper
    buffer::Vector{UInt8}
end
# --- Main Rx structure 
mutable struct BladeRFRx
    rtlsdr::BladeRFRxWrapper
    carrierFreq::Float64
    samplingRate::Float64;
    gain::Union{Int,Float64}; 
    antenna::String;
    packetSize::Csize_t;
    released::Int;
end

# --- Main Tx structure 
mutable struct BladeRFTx 
    rtlsdr::BladeRFTxWrapper
    carrierFreq::Float64
    samplingRate::Float64
    gain::Union{Int,Float64}
    antenna::String
    packetSize::Csize_t
    released::Int
end

# --- Complete structure 
mutable struct BladeRFBinding
    radio::Ref{Ptr{bladerf}}
    rx::BladeRFRx 
    tx::BladeRFTx
end



function openBladeRF(carrierFreq,samplingRate,gain;agc_mode=0,tuner_gain_mode=0)
    # Probalby more in scan part 
    ptr_devinfo = Ref{Ptr{bladerf_devinfo}}
    bladerf_init_devinfo(ptr_devinfo[])

    # --- Instantiate a new BladeRF device 
    ptr_bladerf = Ref{Ptr{bladerf}}()
    status = bladerf_open_with_devinfo(ptr_bladerf,ptr_devinfo[])
    @info "Open BladeRF with status $status"

    
    # ----------------------------------------------------
    # --- Wrap all into a custom structure 
    # ----------------------------------------------------  
    # Instantiate a buffer to handle async receive. Size is arbritrary and will be modified afterwards 
    buffer = zeros(UInt8,512)
    rtlsdrRx = BladeRFRxWrapper(buffer)
    rtlsdrTx = BladeRFTxWrapper(buffer)
    rx = BladeRFRx(
                  rtlsdrRx,
                  carrierFreq,
                  samplingRate,
                  0,
                  "RX",
                  0,
                  0
                 );
    tx = BladeRFTx(
                  rtlsdrTx,
                  carrierFreq,
                  samplingRate,
                  0,
                  "TX",
                  0,
                  0
                 );    
    radio = BladeRFBinding(
                          ptr_bladerf,
                          rx,
                          tx
    )
    return radio
end


end
