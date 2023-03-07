# ----------------------------------------------------
# --- Mutators.jl
# ---------------------------------------------------- 
# Functions to update radio configuration and parameters 
"""
Update carrier frequency of current radio device, and update radio object with the new obtained sampling frequency.
# --- Syntax
updateCarrierFreq!(radio,carrierFreq)
# --- Input parameters
- radio	  : SDR device
- carrierFreq	: New desired carrier frequency
# --- Output parameters
- carrierFreq : Effective carrier frequency
"""
updateCarrierFreq!(obj::SDROverNetwork,tul...) = SDROverNetworks.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::UHDBinding,tul...) = UHDBindings.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::RadioSim,tul...) = RadioSims.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::RTLSDRBinding,tul...) = RTLSDRBindings.updateCarrierFreq!(obj,tul...);
updateCarrierFreq!(obj::BladeRFBinding,tul...) = BladeRFBindings.updateCarrierFreq!(obj,tul...);
function updateCarrierFreq!(obj::PlutoSDR,tul...)
    # In pluto we only get a flag so we need to call to the accessor
    AdalmPluto.updateCarrierFreq!(obj,_toInt.(tul)...);
    return getCarrierFreq(obj)
end

"""
Update sampling rate of current radio device, and update radio object with the new obtained sampling frequency.
# --- Syntax
updateSamplingRate!(radio,samplingRate)
# --- Input parameters
- radio	  : SDR device
- samplingRate	: New desired sampling rate
# --- Output parameters
- samplingRate : Effective sampling rate
"""
updateSamplingRate!(obj::SDROverNetwork,tul...) = SDROverNetworks.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::UHDBinding,tul...) = UHDBindings.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::RadioSim,tul...) = RadioSims.updateSamplingRate!(obj,tul...);
updateSamplingRate!(obj::RTLSDRBinding,tul...) = RTLSDRBindings.updateSamplingRate!(obj,tul...);
function updateSamplingRate!(obj::BladeRFBinding,tul...)
    BladeRFBindings.updateSamplingRate!(obj,tul...);
    BladeRFBindings.updateRFBandwidth!(obj,tul...);
end 
function updateSamplingRate!(obj::PlutoSDR,tul...) 
    # For Adalm Pluto we should also update the RF filter band 
    AdalmPluto.updateSamplingRate!(obj,_toInt.(tul)...);
    fs = getSamplingRate(obj)
    # Which policy ? Here we use 25% roll off 
    α = 1.00
    brf = fs * α
    AdalmPluto.updateBandwidth!(obj,_toInt.(brf)...);
    # Update ADC policy (filter coefficients) based on frequency 
    AdalmPluto.ad9361_baseband_auto_rate(C_iio_context_find_device(obj.ctx, "ad9361-phy"), Int(fs));
    return fs
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
- gain : New gain value
"""
updateGain!(obj::SDROverNetwork,tul...) = SDROverNetworks.updateGain!(obj,tul...);
updateGain!(obj::UHDBinding,tul...) = UHDBindings.updateGain!(obj,tul...);
updateGain!(obj::RadioSim,tul...) = RadioSims.updateGain!(obj,tul...);
updateGain!(obj::RTLSDRBinding,tul...) = RTLSDRBindings.updateGain!(obj,tul...);
updateGain!(obj::BladeRFBinding,tul...) = BladeRFBindings.updateGain!(obj,tul...);
function updateGain!(obj::PlutoSDR,tul...) 
    # In pluto we only get a flag so we have to access to gain value to return the updated gain value 
    AdalmPluto.updateGain!(obj,_toInt.(tul)...);
    return getGain(obj)
end


""" 
Define Gain policy for the SDR radio. Only supported on AdalmPluto 
""" 
updateGainMode!(sdr::AbstractSDR) = "manual"
# No need to redefine  for Pluto backend

