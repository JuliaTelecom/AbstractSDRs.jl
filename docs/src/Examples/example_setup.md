# Set up a Radio Link and get some samples

We use a UHD based device. In order to get 4096 samples at 868MHz with a instantaneous bandwidth of 16MHz, with a 30dB Rx Gain, the following Julia code should do the trick. 

	function main()
		# ---------------------------------------------------- 
		# --- Physical layer and RF parameters 
		# ---------------------------------------------------- 
		carrierFreq	= 868e6; 	# --- The carrier frequency (Hz)	
		samplingRate	= 16e6;         # --- Targeted bandwidth (Hz)
		rxGain		= 30.0;         # --- Rx gain (dB)
		nbSamples	= 4096;         # --- Desired number of samples
	
		# ---------------------------------------------------- 
		# --- Getting all system with function calls  
		# ---------------------------------------------------- 
		# --- Creating the radio resource 
		radio	= openSDR(:uhd,carrierFreq,samplingRate,rxGain);
		# --- Display the current radio configuration
		print(radio);
		# --- Getting a buffer from the radio 
		sigAll	= recv(radio,nbSamples);
		# --- Release the radio resources
		close(radio); 
	end
