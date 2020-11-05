using Plots

function getMarker(ind)
	dict = [:rect,:utriangle,:diamond,:circle,:cross,:diamond,:dtriangle,:pentagon,:rect,:star,:utriangle,:vline,:xcross,:hline];
	# dict = ["square*","triangle*","diamond*","*","pentagon*","rect","star","utriangle","vline","xcross","hline"];
	ll = length(dict)
	return dict[mod(ind - 1, ll) + 1];
end




""" 
--- 
Get Latex color for PGF plotds 
--- Syntax 
c = getColorLatex(ind,size=1)
# --- Input parameters 
- ind	  : Desired color index [Int]
- Size	  : Number of color to be generated (necessary ind ind > 5)
# --- Output parameters 
- a		  : RGB sequence [Char]
# --- 
# v 1.0 - Robin Gerzaguet.
"""
function getColorLatex(index, size = 1);
	if index > 5 
		size = index;
	end
	if size < 5 
		# ---------------------------------------------------- 
		# --- Manual color generation 
		# ---------------------------------------------------- 
		c	= ();
		# --- Manually create colors 
		c	= (c..., "rgb,1:red,0; green,0.44700; blue,0.74100");
		# c	= (c..., RGB(0,0.447,0.74100));
		c	= (c..., "orange");
		c	= (c..., "violet");
		c	= (c..., "green!80!black");
		c	= (c..., "black");
		col  = c[index];
	else 
		# ---------------------------------------------------- 
		# --- Automatic color generation 
		# ---------------------------------------------------- 
		col = distinguishable_colors(size);#
		r	= Int(floor(col.r * 255));
		b	= Int(floor(col.b * 255));
		g	= Int(floor(col.g * 255));
		col = "rgb,255:red,$r; green,$g; blue,$b";
		# col = RGB(r,b,g);
	end 
	return col;
end


function plotPerf(strucRes);
    # p = plot(tex_output_standalone = true,size=(400,300));           # for iN = 1 : 1 : size(strucRes.benchPerf,1)
    p = plot();
    p = plot!(p,strucRes.radioRate./1e6,strucRes.radioRate./1e6,markersize = 4,marker=getMarker(3),label="Ideal",line=1.5);
    p = plot!(p,strucRes.radioRate./1e6,strucRes.effectiveRate./1e6,markersize = 5,marker=getMarker(1),label="Obtained",line=1.5);
        xlabel!("Target rate [MS/s]");
    ylabel!("Obtained rate [MS/s]")
    ylims!(0,16);
    display(p);
    return p
end

plotlyjs();
# plt = plotPerf(res);
# display(plt)
