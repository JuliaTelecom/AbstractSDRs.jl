
# Benchmark for Rx link 

The following script allows to benchmark the effective rate from the receiver. To do so we compute the number of samples received in a given time. The timing is measured fro the timestamp obtained from the radio. 

	module Benchmark 
	# ---------------------------------------------------- 
	# --- Modules & Utils
	# ---------------------------------------------------- 
	# --- External modules 
	using UHDBindings 
	# --- Functions 
	"""
	Calculate rate based on UHD timestamp
	"""
	function getRate(tInit,tFinal,nbSamples)
		sDeb = tInit.intPart + tInit.fracPart;
		sFin = tFinal.intPart + tFinal.fracPart; 
		timing = sFin - sDeb; 
		return nbSamples / timing;
	end
	"""
	Main call to monitor Rx rate
	"""
	function main(samplingRate)	
		# ---------------------------------------------------- 
		# --- Physical layer and RF parameters 
		# ---------------------------------------------------- 
		# --- Create the radio object in function
		carrierFreq		= 770e6;		
		gain			= 50.0; 
		radio			= openUHD("Rx",carrierFreq,samplingRate,gain); 
		# --- Print the configuration
		print(radio);
		# --- Init parameters 
		# Get the radio size for buffer pre-allocation
		nbSamples 		= radio.packetSize;
		# We will get complex samples from recv! method
		sig		  = zeros(Complex{Cfloat},nbSamples); 
		# --- Targeting 2 seconds acquisition
		# Init counter increment
		nS		  = 0;
		# Max counter definition
		nbBuffer  = 2*samplingRate;
		# --- Timestamp init 
		p 			= recv!(sig,radio);
		nS			+= p;
		timeInit  	= Timestamp(getTimestamp(radio)...);
		while true
			# --- Direct call to avoid allocation 
			p = recv!(sig,radio);
			# --- Ensure packet is OK
			err 	= getError(radio);
			# --- Update counter
			nS		+= p;
			# --- Interruption 
			if nS > nbBuffer
				break 
			end
		end
		# --- Last timeStamp and rate 
		timeFinal = Timestamp(getTimestamp(radio)...);
		# --- Getting effective rate 
		radioRate	  = radio.samplingRate;
        effectiveRate = getRate(timeInit,timeFinal,nS);
		# --- Free all and return
		close(radio);
		return (radioRate,effectiveRate);
	    end
    end
