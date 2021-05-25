# ----------------------------------------------------
# --- Mutators.jl
# ---------------------------------------------------- 
# Functions to update radio configuration and parameters 

updateCarrierFreq!(obj::SDROverNetwork,tul...) = SDROverNetworks.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::UHDBinding,tul...) = UHDBindings.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::RadioSim,tul...) = RadioSims.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::RTLSDRBinding,tul...) = RTLSDRBindings.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::PlutoSDR,tul...) = AdalmPluto.updateCarrierFreq!(obj,_toInt.(tul)...);

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
updateSamplingRate!(obj::SDROverNetwork,tul...) = SDROverNetworks.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::UHDBinding,tul...) = UHDBindings.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::RadioSim,tul...) = RadioSims.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::RTLSDRBinding,tul...) = RTLSDRBindings.updateSamplingRate!(obj,tul...);
function updateSamplingRate!(obj::PlutoSDR,tul...) 
    # For Adalm Pluto we should also update the RF filter band 
    AdalmPluto.updateSamplingRate!(obj,_toInt.(tul)...);
    AdalmPluto.updateBandwidth!(obj,_toInt.(tul)...);
    return obj.rx.effectiveSamplingRate 
end

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
updateGain!(obj::SDROverNetwork,tul...) = SDROverNetworks.updateGain!(obj,tul...);
updateGain!(obj::UHDBinding,tul...) = UHDBindings.updateGain!(obj,tul...);
updateGain!(obj::RadioSim,tul...) = RadioSims.updateGain!(obj,tul...);
updateGain!(obj::RTLSDRBinding,tul...) = RTLSDRBindings.updateGain!(obj,tul...);
updateGain!(obj::PlutoSDR,tul...) = AdalmPluto.updateGain!(obj,_toInt.(tul)...);

""" 
Define Gain policy for the SDR radio. Only supported on AdalmPluto 
""" 
updateGainMode!(sdr::AbstractSDR) = "manual"
# No need to redefine  for Pluto backend

