module JuliaProcessingServer

export StartProcessingServer

# using Sockets
using Memento
#using Logging


logger = Memento.config!("info",fmt="[{date} | {level}]: {msg}")
# @Logging.configure(level=INFO,output=open("logfile_JuliaServerForMath.log", "a"))

"""
StartProcessingServer(ListenSOCKET::Int, ReaderFunction, ProcessFunction, PackerFunction[, logger])

Starts a Processing Server, which will listen to localhost:ListenSOCKET port
When any clients send any data, it will be read using the ReaderFunction
The read in data will then be passed on to ProcessFunction
Output from the ProcessFunction will be serialised using the PackerFunction function before writing back to the connected socket.

Optional, Memento logger can be provided to send the logs to a custom location.

"""
function StartProcessingServer(ListenSOCKET::Int,ReaderFunction::Function,ProcessFunction::Function,PackerFunction::Function;logger=logger)
    server = listen(ListenSOCKET)
    while true
        info(logger,"Server Listening on $ListenSOCKET")
        sock = accept(server)
        @async while isopen(sock)
            receiveddata = ReaderFunction(sock) 
            info(logger,"Received Array of size $(size(receiveddata))")
            # println(receiveddata)
	    ProcessedData = ProcessFunction(receiveddata)
            # write(sock,PackerFunction(ProcessedData))
	    # println(ProcessedData)
            PackerFunction(sock,ProcessedData)
	    info(logger,"Data Returned")
	    close(sock)
        end

    end
end

"""
When PackerFunction is not provided, start a server which doesnot send anything back.
"""
function StartProcessingServer(ListenSOCKET::Int,ReaderFunction::Function,ProcessFunction::Function;logger=logger)
    server = listen(ListenSOCKET)
    while true
        info(logger,"Server Listening on $ListenSOCKET")
        sock = accept(server)
        @async while isopen(sock)
            receiveddata = ReaderFunction(sock) 
            info(logger,"Received Array of size $(size(receiveddata))")
            # println(receiveddata)
	    ProcessFunction(receiveddata)
	    info(logger,"Closing connection")
	    close(sock)
        end

    end
end

end # module JuliaProcessingServer

