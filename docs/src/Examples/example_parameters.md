# Update parameters of the radio 

It is possible to update the radio parameter such as the gain, the bandwidth and the sampling rate. 
In this function, we change the carrier frequency to 2400MHz, the bandwidth from 16MHz to 100MHz and the Rx gain from 10 to 30dB.
In some cases, the desired parameters cannot be obtained. In such a case, we let UHD decide what is the most appropriate value. A warning is raised and the output of the functions used to change the 
the radio parameters corresponds to the effective values of the radio. 


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
		# The first parameter is for specific parameter (FPGA bitstream, IP address)
		radio	= openUHD("Rx",carrierFreq,samplingRate,rxGain);
		# --- Display the current radio configuration
		print(radio);
		# --- We what to change the parameters ! 
		updateSamplingFreq!(radio,100e6);
		updateCarrierFreq!(radio,2400e6);
		updateGain!(radio,30)
		# --- Print the new radio configuration 
		print(radio);
		# --- Release the radio resources
		close(radio); 
	end

