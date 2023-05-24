using AbstractSDRs 

""" A simple sine wave transmitter 
"""



function main()
    carrierFreq = 868e6 
    samplingRate = 40e6 
    gain = 20
    sdr = :bladerf 

    #N = 1_000_000 
    N = 8192 * 16
    fc = 0.5e6 

    fc      = -1.0e6;
    ω       = 2*pi * fc / samplingRate;
    #
    d = 0.5*[exp(1im*ω.*n) for n ∈ (0:N-1)];
    radio = openSDR(sdr,carrierFreq,samplingRate,gain)
    print(radio)

    cnt = 0 
    ϕ  = 0
    try 
        while(true) 
            d = d * exp(1im*ϕ)
            ϕ = angle(d[end])
            send(radio,d,false)
            cnt += 1
        end
    catch(exception)
        close(radio) 
        @info "Transmitted $cnt buffers"
        rethrow(exception) 
    end 

end


main()
