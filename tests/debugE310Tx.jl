
using AbstractSDRs



# --- Main parameters 
carrierFreq		= 440e6;	# --- The carrier frequency 	
samplingRate	= 4e6;         # --- Targeted bandwdith 
gain			= 0.0;         # --- Rx gain  
ipAddr          = "192.168.10.12";
nbSamples		= 1016*4;
# --- Create the E310 device 
E310 = openSDR("E310", carrierFreq, samplingRate, gain;ip=ipAddr);
print(E310);
sleep(2);
@info "Ready"
updateCarrierFreq!(E310, 770e6);
print(E310);

freq    = 800;
sig  = convert.(Complex{Cfloat},([1+exp.(2im * π *freq / samplingRate * n) for n ∈ (0:nbSamples-1)]));
send(sig,E310,true);


close(E310);