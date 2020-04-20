#  using Pkg; Pkg.develop(PackageSpec(path="../UHD"));Pkg.activate(".");
module E310

# ----------------------------------------------------
# --- Module loading
# ----------------------------------------------------
# --- Module dependency
using UHD 
using Sockets 
# --- Constant definition
const HOST_ADDRESS 		= @ip_str "192.168.10.60";
const E310_ADRESS 	= @ip_str "0.0.0.0";
const PORTHE			= 30000;
const PORTEH 			= 36000;
# --- Global variables 
flag 			= false;
requestConfig 	= false;
requestMD  		= false;
res 			= Any; 


mutable struct Configuration
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Float64,Int};
	Antenna::String;
	nbSamples::Int;
end
mutable struct MD
	error::Cint;
	timeStamp::Timestamp;
end

# ----------------------------------------------------
# --- Internal functions
# ----------------------------------------------------
# Setting max piority to avoid CPU congestion 
function setMaxPiority();
	pid = getpid();
	run(`renice -n -20 -p $pid`);
	run(`chrt  -p  99 $pid`)
end 

# --- Socket for radio config update
function updateConfig(configHE);
	# --- Container for 
	global res;
	# --- Raising interruption for radio config
	global flag
	try 
		while(true);
			# --- Waiting a new config 
			receiver = Sockets.recv(configHE);
			# --- Updating container with new config 
			global res = Meta.parse(String(receiver));
			# --- Update flag 
			global flag = true;
		end 
	catch exception;
		@show(exception);
		end
end


# --- To effectively update the radio config
function updateUHD!(radio,res)
	# --- We update the config 
	eval(res);
	# --- We compute the radio update based on what we receive
	str = string(res);
	# --- As the radio config is updated, we will send back the config to PC 
	global requestConfig = true;
	global requestMD = false;
	# --- Update radio config based on received content
	if !isnothing(findfirst("carrierFreq",str));
		# --- UHD call to update carrier frequency
		updateCarrierFreq!(radio,carrierFreq);
	elseif !isnothing(findfirst("gain",str));
		# --- UHD call to update gain 
		updateGain!(radio,gain);
	elseif !isnothing(findfirst("samplingRate",str));
		# --- UHD call to update sampling rate
		updateSamplingRate!(radio,samplingRate);
	elseif !isnothing(findfirst("requestMD",str)); 
		# Set the flag to send the current radio state
		requestConfig = false;
		global requestMD = true;
	elseif !isnothing(findfirst("requestConfig",str)); 
		# We have ask a new config, so nothing to do 

	else 
		# False alarm, or nothing to push back to host 
		requestConfig = false;
	end
end

function sendConfig(configEH,radio,nbSamples)
	# --- get Configuration from radio 
	config = (radio.carrierFreq,radio.samplingRate,radio.gain,radio.antenna,nbSamples);
	# --- Send config 
	strF = "$(config)";
	Sockets.send(configEH,HOST_ADDRESS,PORTEH,strF);
end
function sendMD(configEH,radio)
	md = (getTimestamp(radio)...,Cint(getError(radio)));
	# --- Send config 
	strF = "$(md)";
	Sockets.send(configEH,HOST_ADDRESS,PORTEH,strF);
end

# ----------------------------------------------------
# --- Main call
# ----------------------------------------------------
function main(carrierFreq0,samplingRate0,gain0,nbSamples)
	# --- Setting high priority for the process
	setMaxPiority();
	# --- Global scope config 
	carrierFreq = carrierFreq0;
	samplingRate 	= samplingRate0;
	gain 		= gain0;
	# --- Setting a very first configuration 
	radio = openUHDRx(carrierFreq,samplingRate,gain); 
	# --- Create socket for data transmission
	dataSocket = UDPSocket();
	# --- Get samples 
	sig		  = zeros(Complex{Cfloat},nbSamples); 
	cnt		  = 0;
	# --- Start sockets 
	# Data socket 
	configHE = UDPSocket();
	Sockets.setopt(dataSocket;multicast_loop=false)
	# Socket to get info from Host 
	Sockets.bind(configHE,E310_ADRESS,PORTHE,reuseaddr=true);
	# Socket to push back infos 
	configEH = UDPSocket();
	# Start monitoring server 
	@async updateConfig(configHE);
	# --- Containers for radio config
	global flag = false;
	global requestMD = false;
	global requestConfig = false;
	global res = Any;
	try 
		while(true) 
			# --- Interruption to update radio config 
			if flag 
				# --- Flag update 
				@info "Configuration for the radio";
				flag 	= false;
				# --- UHD update 
				updateUHD!(radio,res);
				# --- Print res (need sleep to see something)
				print(radio);
				sleep(0.010);
			end
			if requestConfig 
				# --- Sending the  configuration to Host 
				sendConfig(configEH,radio,nbSamples);
				requestConfig = false;
			end
			if requestMD
				sendMD(configEH,radio);
				requestMD = false;
			end
			# --- Direct call to avoid allocation 
			recv!(sig,radio);
			# --- To UDP socket
			Sockets.send(dataSocket,HOST_ADDRESS,2001,sig);
		end
	catch exception;
		# --- Close UHD
		close(radio);
		# --- Close sockets
		close(dataSocket);
		close(configHE);
		close(configEH);
		# --- Release USRP 
        @show exception;
	 end
end

end
