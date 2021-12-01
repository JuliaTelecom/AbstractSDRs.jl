module Printing 
using Printf

# This module is intended to provide fancy macros to display warning

export @inforx, @warnrx;
export @infotx, @warntx;
# ----------------------------------------------------
# --- Fancy prints
# ---------------------------------------------------- 
# To print fancy message with different colors with Tx and Rx
function customPrint(str,handler;style...)
    msglines = split(chomp(str), '\n')
    printstyled("┌",handler,": ";style...)
    println(msglines[1])
    for i in 2:length(msglines)
        (i == length(msglines)) ? symb="└ " : symb = "|";
        printstyled(symb;style...);
        println(msglines[i]);
    end
end
# define macro for printing Rx info
macro inforx(str)
    quote
        customPrint($(esc(str)),"Rx";bold=true,color=:light_green)
    end
end
# define macro for printing Rx warning 
macro warnrx(str)
    quote
        customPrint($(esc(str)),"Rx Warning";bold=true,color=:light_yellow)
    end
end
# define macro for printing Tx info
macro infotx(str)
    quote
        customPrint($(esc(str)),"Tx";bold=true,color=:light_blue)
    end
end
# define macro for printing Tx warning 
macro warntx(str)
    quote
        customPrint($(esc(str)),"Tx Warning";bold=true,color=:light_yellow)
    end
end


end
