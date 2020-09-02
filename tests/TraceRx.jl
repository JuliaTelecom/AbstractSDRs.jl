using FFTW 
using AbstractSDRs

# ---------------------------------------------------- 
# --- Physical layer and RF parameters 
# ---------------------------------------------------- 
carrierFreq		= 770e6;		
samplingRate	= 5.33e6; 
gain			= 25;
nbSamples		= 1016;

# --- Setting a very first configuration 
radio = openSDR("E310",carrierFreq,samplingRate,gain;ip="192.168.10.11"); 
print(radio);
# --- Get samples 
sig= recv(radio, nbSamples);
# --- Release USRP 
close(radio);


