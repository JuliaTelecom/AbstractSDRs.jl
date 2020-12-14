module TestE310Rx

using AbstractSDRs

# Testing E310 device, with the use of SDROverNetwork
function main()

    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 4e6;         # --- Targeted bandwdith 
    gain			= 0.0;         # --- Rx gain  
    ipAddr          = "192.168.10.13";
	nbSamples		= 2048;
    # --- Create the E310 device 
    # E310 = openSDR(:e310,carrierFreq,samplingRate,gain;addr=ipAddr);
    # E310 = openSDR(:e310,carrierFreq,samplingRate,gain;packetSize=1024,args="addr=$ipAddr");
    E310 = openSDR(:sdr_over_network,carrierFreq,samplingRate,gain;packetSize=1024,args="addr=$ipAddr");
    print(E310);
    sleep(2);
    @info "Ready"
    updateCarrierFreq!(E310,770e6);
    print(E310);
    # 
    sig = recv(E310,nbSamples)
    @show size(sig);
    @show getError(E310)
    @show getTimestamp(E310)
    # 
    close(E310);
end


end
