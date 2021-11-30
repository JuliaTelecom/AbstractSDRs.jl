# Example of MIMO use (with UHD)

Multiple antenna support is handled with the USRP (at least) based on the API proposed by UHD.
Some extra parameters (channels, board and antennas) have to be set up according to the targeted board.
The following example works for the USRP e310 and configure the radio to have its two receive antenna. The spectrum of the two channel is then depicted. 
For other radio support, MIMO configuration should be modified to be compliant with the driver preriquisites. 



    # ----------------------------------------------------
    # --- Package dependencies 
    # ---------------------------------------------------- 
    using AbstractSDRs 
    using Plots 
    using FFTW
    
    
    # ----------------------------------------------------
    # --- Radio parameters 
    # ---------------------------------------------------- 
    radioType   = :uhd      # We target UHDBindings here 
    carrierFreq = 2410e6     # Carrier frequency (ISM band)
    samplingRate = 2e6      # Not high but issue with e310 stream :( 
    gain        = 50        # In dB 
    
    
    # ----------------------------------------------------
    # --- MIMO and board specificities 
    # ---------------------------------------------------- 
    # We need to specify the channels and the board as we use a USRP => Note that the way the parameters are set is based on how it is done at UHD level. You can have a look at the mimo example provided by UHD.
    # This may vary depending on the chosen hardware 
    # /!\ We need to specify how many antenna we want. Be sure that the configuration is handled by the hardware you have otherwise UHD will raise an error (and maybe segfault ?)
    nbAntennaRx = 2
    nbAntennaTx = 0
    # Antenna and board config
    channels    = [0;1]     # First channel is the first path 
    subdev      = "A:0 A:1" # e310 board names 
    # For the antenna, we need to specify the dictionnary of the allocated antenna for both Tx and Rx. In our case we will only do full Rx mode so we only specify the :Rx key 
    antennas    = Dict(:Rx => ["TX/RX";"RX2"])
    
    # ----------------------------------------------------
    # --- Open radio 
    # ---------------------------------------------------- 
    radio = openSDR(
                    radioType,
                    carrierFreq,
                    samplingRate,
                    gain ;
                    nbAntennaTx, nbAntennaRx, 
                    channels,
                    antennas,
                    subdev)
    
    
    # --- Receive a buffer
    # We specify the size of each buffer 
    # We will have one buffer per channel so a Vector of Vector 
    # sigVect[1] and sigVect[2] will have the same size (of nbSamples) each for a channel
    nbSamples = 4096 
    sigVect = recv(radio,nbSamples)
    
    
    # ----------------------------------------------------
    # --- Plot the spectrum 
    # ---------------------------------------------------- 
    # Get the rate from the radio using the accessor 
    s = getSamplingRate(radio)
    # X axis 
    xAx = ((0:nbSamples-1)./nbSamples .- 0.5) * s
    # PSD 
    y = 10*log10.(abs2.(fftshift(fft(sigVect[1]))))
    plt = plot(xAx,y,label="First Channel")
    y = 10*log10.(abs2.(fftshift(fft(sigVect[2]))))
    plot!(plt,xAx,y,label="Second Channel")
    xlabel!("Frequency [Hz]")
    ylabel!("Magnitude [dB]")
    display(plt)
    
    
    # ----------------------------------------------------
    # --- Close radio 
    # ---------------------------------------------------- 
    close(radio)
