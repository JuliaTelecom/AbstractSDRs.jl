module Benchmark 
# ---------------------------------------------------- 
# --- Modules & Utils
# ---------------------------------------------------- 
# --- External modules 
using AbstractSDRs 
# --- Functions 
"""
Calculate rate based on Julia timing
"""
function getRate(tInit,tFinal,nbSamples)
	return nbSamples / (tFinal-tInit);
end


"""
Main call to monitor Rx rate
"""
function main(radio,samplingRate)	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	# --- Create the radio object in function
	carrierFreq		= 770e6;		
	gain			= 50.0; 
	updateSamplingRate!(radio,samplingRate);
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
	pInit 			= recv!(sig,radio);
	timeInit  	= time();
	while true
		# --- Direct call to avoid allocation 
		p = recv!(sig,radio);
		# # --- Ensure packet is OK
		# err 	= getError(radio);
		# (p != pInit) && (print("."));
		# --- Update counter
		nS		+= p;
		# --- Interruption 
		if nS > nbBuffer
			break 
		end
	end
	# --- Last timeStamp and rate 
	timeFinal = time();
	# --- Getting effective rate 
	radioRate	  = radio.samplingRate;
    effectiveRate = getRate(timeInit,timeFinal,nS);
	# --- Free all and return
	return (radioRate,effectiveRate);
end


struct Res 
	radio::String;
	carrierFreq::Float64;
	gain::Float64;	
	rateVect::Array{Float64};
	effectiveRate::Array{Float64};
	radioRate::Array{Float64};
end
export Res


function bench()
	# --- Set priority 
	# --- Configuration
	radioName 		= "e310";
	carrierFreq		= 770e6;		
	gain			= 50.0; 
	# rateVect	= [1e3;100e3;500e3;1e6:1e6:8e6;16e6;32e6;64e6;80e6;100e6;200e6];
	rateVect	= [1e3;100e3;500e3;1e6:1e6:8e6;16e6];
	effectiveRate	= zeros(Float64,length(rateVect));
	radioRate	= zeros(Float64,length(rateVect));
	# --- Setting a very first configuration 
	global radio = openSDR(radioName,carrierFreq,1e6,gain;ip="192.168.10.12"); 
	for (iR,targetRate) in enumerate(rateVect)
		(rR,eR) = main(radio,targetRate);
		radioRate[iR] = rR;
		effectiveRate[iR] = eR;
	end
	close(radio);
	strucRes  = Res(radioName,carrierFreq,gain,rateVect,effectiveRate,radioRate);
	# @save "benchmark_UHD.jld2" res;
	return strucRes;
end

end