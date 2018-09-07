#!/usr/bin/env julia
# This is a Julia Processing server to do non-linearity correction of HPF data

using NPZ
@everywhere using Dierckx
@everywhere using JLD
using Memento
include("/storage/home/jpn23/scratch/JuliaServerForMath.jl/src/JuliaProcessingServer.jl")
using JuliaProcessingServer

logger = Memento.config!("info",fmt="[{date} | {level}]: {msg}")
push!(logger, DefaultHandler("/storage/home/j/jpn23/scratch/logfile_JuliaServerForMath.log",DefaultFormatter("[{date} | {level}]: {msg}")))

info(logger,"Loading the NLcorrTCKdic from jdl file")

# #Load and merge the Nonlinearity dictionaires in parallel
# NLcorrTCKdic = @parallel merge for i in 0:128:1920
#     jldfilename = "/storage/home/j/jpn23/scratch/LongRamp/BSPLINE_NLC_20171117_$i-$(i+128).jld"
#     load(jldfilename, "NLcorrTCKdic")
# end

#Load the NLCdictionaries as a list without merging
ListOfNLcorrTCKdic = pmap((fname)->load(fname,"NLcorrTCKdic"), ["/storage/home/j/jpn23/scratch/LongRamp/BSPLINE_NLC_20171117_$i-$(i+128).jld" for i in 0:128:1920])

# NLcorrTCKdic = load("/storage/home/j/jpn23/scratch/LongRamp/BSPLINE_NLC_20171117_0-128.jld", "NLcorrTCKdic")
info(logger,"Finished Loading the NLcorrTCKdic from jdl file")
function ApplyNonLinearityCorrection(datacube)
    datacube = SharedArray(datacube)
    @parallel for NLcorrTCKdic in ListOfNLcorrTCKdic
        for ij in keys(NLcorrTCKdic)
            tck = NLcorrTCKdic[ij]
            # Since Julia has 1 indexing, we should add +1 to python coorindates to match julia's coordinates
    	    datacube[:,ij[1]+1,ij[2]+1] = Dierckx._evaluate(tck[1],tck[2],tck[3],datacube[:,ij[1]+1,ij[2]+1],0) 
        end
    end
    return datacube
end

#################################
ListenSOCKET = 8006
ReaderFunction = NPZ.npzreadarray   # Function to read .npy file received via socket
ProcessFunction = ApplyNonLinearityCorrection # Function to apply on to the recived data
PackerFunction = NPZ.npzwritearray # Function to write .npy file to be send via socket
##################################

open("/storage/home/jpn23/scratch/NonLinCorrServerStarted.txt", "w") do f
    write(f, "NonLinCorr Julia Server Started\n")
end
StartProcessingServer(ListenSOCKET,ReaderFunction,ProcessFunction,PackerFunction;logger=logger)
