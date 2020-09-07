#  using Pkg; Pkg.develop(PackageSpec(path="../UHD"));Pkg.activate(".");
@info "Julia-based minimal transceiver";

using Distributed 
module E310

# ----------------------------------------------------
# --- Module loading
# ----------------------------------------------------
# --- Module dependency
using UHDBindings 
using Distributed 
using ZMQ
@everywhere using Sockets 
# --- Constant definition
# const HOST_ADDRESS 		= @ip_str "192.168.10.60";
const E310_ADRESS 	= @ip_str "0.0.0.0";
const PORTHE			= 30000;
const PORTEH 			= 30000;

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

# Setting max piority to avoid CPU congestion 
function setMaxPriority();
	pid = getpid();
	run(`renice -n -20 -p $pid`);
	run(`chrt -p 99 $pid`)
end 


# ----------------------------------------------------
# --- Main call
# ----------------------------------------------------
function main(carrierFreq, samplingRate, gain, nbSamples)
	# --- Setting a very first configuration 
    global radio = openUHD(carrierFreq, samplingRate, gain); 
	# --- Create socket for data transmission
    dataSocket = ZMQ.Socket(PUB);
    bind(dataSocket,"tcp://*:9999");
    # --- Create ZMQ socket for config transmission to Host
    configEH = ZMQ.Socket(PUB)
    bind(configEH,"tcp://*:30000");
    # --- Create ZMQ socket for config reception from Host 
    configHE = ZMQ.Socket(SUB);
    tcpSys		 = string("tcp://*:55555");
    ZMQ.subscribe(configHE);
    ZMQ.bind(configHE,tcpSys)
    # ZMQ.connect(configHE,tcpSys);
	# --- Get samples 
	sig		  = zeros(Complex{Cfloat}, nbSamples); 
    cnt		  = 0;
    # --- Mode used 
    mode    = :rx;
    # --- Processing
	try 
        while (true) 
            print(radio);
            # --- Second order loop setup
            flag      = false;
			# --- Interruption to update radio config 
            @async begin 
                # --- We wait in this @async for a reception 
                receiver = ZMQ.recv(configHE);
                @info "We have receive something from remote PC"
                # --- Here, we have receive something
                # Raise a flag because something happens 
                flag = true;
                # we create an evaluation here 
                res = Meta.parse(String(receiver));
                # and we update the radio and get back the desired feeback level
                (requestConfig, requestMD, mode) = updateUHD!(radio, res);
			    if requestConfig 
			    	# --- Sending the  configuration to Host 
			    	sendConfig(configEH, radio.rx, nbSamples);
			    end
			    if requestMD
			    	sendMD(configEH, radio.rx);
                end
                if mode == :tx 
                    # reevaluate selection 
                    D = eval(res);
                    # sig     = D[:tx];
                end
                # --- Recreate a new socket due to the new config 
            end
            while (!flag)
                if mode == :rx 
			        # --- Direct call to avoid allocation 
			        recv!(sig, radio);
                    # --- To UDP socket
                    ZMQ.send(dataSocket,sig)
                    yield();
                else 
                    # --- We now transmit data ! 
                    # send(radio,sig);
                end
            end
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


# --- To effectively update the radio config
function updateUHD!(radio, res)
    # --- Default output 
    requestConfig   = true;
    requestMD       = false;
    mode            = :rx;
    # --- We create the dictionnary entry to update the radio config
    D = eval(res);
    # --- Apply the changes
    for key in keys(D)
        elem = D[key];
        if key == :requestMD
            # --- We only ask for MD and not config
            requestMD = true;
            requestConfig  = false;
        elseif key == :requestConfig 
            # --- Nothing to do 
        elseif key == :updateCarrierFreq
            # --- Update the carrier freq 
            updateCarrierFreq!(radio, elem);
        elseif key == :updateSamplingRate
            # --- Update sampling frequency 
            updateSamplingRate!(radio, elem);
        elseif key == :updateGain
            # --- Update Gain
            updateGain!(radio, elem);
        else 
            @warn "Unknown Host order. Ask to update $key field with value $elem which is unknwown"
        end
    end
    return (requestConfig, requestMD,mode);
end


function sendConfig(configEH, radio, nbSamples)
	# --- get Configuration from radio 
	config = (radio.carrierFreq, radio.samplingRate, radio.gain, radio.antenna, nbSamples);
	# --- Send config 
	strF = "$(config)";
    # Sockets.send(configEH, HOST_ADDRESS, PORTEH, strF);
	ZMQ.send(configEH, strF);
end
function sendMD(configEH, radio)
	md = (getTimestamp(radio)..., Cint(getError(radio)));
	# --- Send config 
	strF = "$(md)";
	# Sockets.send(configEH, HOST_ADDRESS, PORTEH, strF);
	ZMQ.send(configEH, strF);
end

end

# call main function 
E310.main(868e6,4e6,10,(512+36)*2*32);
#E310.main(868e6,4e6,10,32768);
