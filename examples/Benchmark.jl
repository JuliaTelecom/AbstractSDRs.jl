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
function main(radio,samplingRate,mode=:rx)	
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
    nbSamples 		= getBufferSize(radio)
	# We will get complex samples from recv! method
	# Fill with random value, as it will be overwritten (and not zero for tx benchmark)
	sig		  = randn(Complex{Cfloat},nbSamples); 
	# --- Targeting 2 seconds acquisition
	# Init counter increment
	nS		  = 0;
	# Max counter definition
	nbBuffer  = 2*samplingRate;
	# --- Timestamp init 
	if mode == :rx
		pInit 			= recv!(sig,radio);
	else 
		pInit 	=send(sig,radio,true;maxNumSamp=nbBuffer); 
	end
	timeInit  	= time();
	while true
		# --- Direct call to avoid allocation 
		if mode == :rx 
			p = recv!(sig,radio);
			# --- Update counter
			nS		+= p;
		elseif mode == :tx
			p = send(sig,radio,true;maxNumSamp=nbBuffer);
			nS += p;
		end
		# --- Interruption 
		if nS > nbBuffer
			break 
		end
	end
	# --- Last timeStamp and rate 
	timeFinal = time();
	# --- Getting effective rate 
    radioRate	  = getSamplingRate(radio)
    effectiveRate = getRate(timeInit,timeFinal,nS);
	# --- Free all and return
	return (radioRate,effectiveRate);
end

function test(radioName,samplingRate;args,duration=2)
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	# --- Create the radio object in function
	carrierFreq		= 770e6;		
	gain			= 50.0; 
    radio = openSDR(radioName,carrierFreq,samplingRate,gain;args)
	# --- Print the configuration
	print(radio);
	# --- Init parameters 
	# Get the radio size for buffer pre-allocation
    nbSamples 		= getBufferSize(radio)
	# We will get complex samples from recv! method
	sig		  = zeros(Complex{Cfloat},nbSamples); 
	# --- Targeting 2 seconds acquisition
	# Init counter increment
	nS		  = 0;
	# Max counter definition
	nbBuffer  = duration*samplingRate;
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
    radioRate	  = getSamplingRate(radio)
	effectiveRate = getRate(timeInit,timeFinal,nS);
	# --- Free all and return
	close(radio);
	return (radioRate,effectiveRate);
end	

struct Res 
	radio::Symbol;
	carrierFreq::Float64;
	gain::Float64;	
	rateVect::Array{Float64};
	effectiveRate::Array{Float64};
	radioRate::Array{Float64};
end
export Res


function benchmark_bench(;radioName=:radioSim,rateVect=[1e3;100e3;500e3;1e6:1e6:8e6;16e6],carrierFreq=770e6,gain=50.0,mode=:rx,args="addr=192.168.10.11")
	# --- Set priority 
	# --- Configuration
	effectiveRate	= zeros(Float64,length(rateVect));
	radioRate	= zeros(Float64,length(rateVect));
	# --- Setting a very first configuration 
    global radio = openSDR(radioName,carrierFreq,1e6,gain;args)
	for (iR,targetRate) in enumerate(rateVect)
		(rR,eR) = main(radio,targetRate,mode);
		radioRate[iR] = rR;
		effectiveRate[iR] = eR;
	end
	close(radio);
	strucRes  = Res(radioName,carrierFreq,gain,rateVect,effectiveRate,radioRate);
	# @save "benchmark_UHD.jld2" res;
	return strucRes;
end


end
