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
    # --- Configuration socket 
    rtcSocket   = ZMQ.Socket(REP);
    bind(rtcSocket, "tcp://*:5555");
    # --- RTT socket for Tx 
    rttSocket   = ZMQ.Socket(REQ);
    bind(rttSocket, "tcp://*:9999");
    # --- Socket for broadcast Rx
    brSocket = ZMQ.Socket(PUB);
    bind(brSocket, "tcp://*:1111");
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
                receiver = ZMQ.recv(rtcSocket);
                @info "We have receive something from remote PC";
                # --- Here, we have receive something
                # Raise a flag because something happens 
                flag = true;
                # we create an evaluation here 
                res = Meta.parse(String(receiver));
                # and we update the radio and get back the desired feeback level
                @show (requestConfig, requestMD, mode) = updateUHD!(radio, res,mode);
			    if requestConfig 
			    	# --- Sending the  configuration to Host 
			    	sendConfig(rtcSocket, radio.rx, nbSamples);
			    end
			    if requestMD
			    	sendMD(rtcSocket, radio.rx);
                end
                if mode == :tx 
                    # reevaluate selection 
                    D = eval(res);
                    # sig     = D[:tx];
                end
            end
            while (!flag)
                if mode == :rx 
			        # --- Direct call to avoid allocation 
			        recv!(sig, radio);
                    # --- To UDP socket
                    ZMQ.send(brSocket, sig)
                elseif mode == :tx 
                    # --- We now transmit data ! 
                    # Wait for RTT from host 
                    ZMQ.send(rttSocket,0x01);
                    # --- Get the data
                    sig = convert.(Complex{Cfloat},ZMQ.recv(rttSocket));
                    # --- Send data to radio
                    UHDBindings.send(radio, sig,false);
                end
                yield();
            end
		end
	catch exception;
		# --- Close UHD
		close(radio);
		# --- Close sockets
		close(rtcSocket);
		close(rttSocket);
		close(brSocket);
		# --- Release USRP 
        rethrow(exception);
	 end
end


# --- To effectively update the radio config
function updateUHD!(radio, res,mode)
    # --- Default output 
    requestConfig   = true;
    requestMD       = false;
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
        elseif key == :mode
            # --- We change mode 
            mode = elem;
            requestConfig = false;
            requestMD = true;
            @info "Change mode to $mode";
        else 
            @warn "Unknown Host order. Ask to update $key field with value $elem which is unknwown"
        end
    end
    return (requestConfig, requestMD, mode);
end


function sendConfig(rtcSocket, radio, nbSamples)
	# --- get Configuration from radio 
	config = (radio.carrierFreq, radio.samplingRate, radio.gain, radio.antenna, nbSamples);
	# --- Send config 
	strF = "$(config)";
	ZMQ.send(rtcSocket, strF);
end
function sendMD(rtcSocket, radio)
	md = (getTimestamp(radio)..., Cint(getError(radio)));
	# --- Send config 
	strF = "$(md)";
	ZMQ.send(rtcSocket, strF);
end

end

# call main function 
E310.main(868e6,4e6,10,(512 + 36) * 2 * 32);
# E310.main(868e6,4e6,10,32768);
