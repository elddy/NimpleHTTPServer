##[
    Simple HTTP server with net sockets
    Compile only with: --threads:on --opt:speed
]##

when not compileOption("threads"):
  {.error: "This module requires the --threads:on option.".}

# Imports
import net, httpcore, strutils, os, times, terminal

# Type HttpServer
type
    HttpServer* = ref object
        port: int
        timeout: int # in seconds
        status: bool

proc newHttpServer*(port: int, timeout = 60): HttpServer = 
    ## Create a new HttpServer instance with the specified
    ## `port` and `timeout`
    result = HttpServer(port: port, timeout: timeout)

# In working http request
var 
    inWorking = false
    stopped {.global.}: bool
    thr: array[0..1, Thread[HttpServer]]

proc status*(s: HttpServer): bool =
    ## Get status of the HttpServer
    if stopped:
        s.status = false
    else:
        s.status = true
    s.status

proc print(STATUS, text: string) =
    ## Prints error or success with nice and coloured output
    if STATUS == "error":
        stdout.styledWrite(fgRed, "[-] ")
    elif STATUS == "success":
        stdout.styledWrite(fgGreen, "[+] ")
    elif STATUS == "loading":
        stdout.styledWrite(fgBlue, "[*] ")
    elif STATUS == "warning":
        stdout.styledWrite(fgYellow, "[!] ")
    stdout.write(text & "\n")

proc stop*(s: HttpServer) =
    ## Stops the server
    if s.status:
        var stopSocket = newSocket()
        try:
            stopSocket.connect("localhost", Port(s.port))
            stopSocket.send("stop" & "\r\L")
        except:
            discard
        finally:
            stopSocket.close()
        s.status = false
        stopped = true
    else:
        print("error", "The server is not running")

proc timeOutStop(s: HttpServer) {.thread.} =
    ## Stops the server thread after the timeout
    if s.timeout > 0:
        var 
            runtime = getTime().toUnix()
            diff = 0'i64
        while diff < s.timeout:
            diff = getTime().toUnix() - runtime    
        s.stop()
        s.status = false

# Forward declaration for startHttpServer
proc startHttpServer(s: HttpServer) {.thread.}


proc start*(s: HttpServer) =
    ## Start the server threads
    s.status = true
    stopped = false
    # Start thread
    createThread(thr[0], startHttpServer, s)
    createThread(thr[1], timeOutStop, s)
    sleep(1) # Needed

proc join*(s: HttpServer) =
    ## Stop everything and wait for the server to end
    if not s.status:
        print("error", "The server is not running")
    joinThreads(thr)

proc validateFile(file: string): bool =
    ## Validate file existence
    echo repr file
    if fileExists(file):
        return true
    print("error", file & "not exist")
    return false

#[
    Help procedures
    ***************
]#

proc addHeaders(msg: var string, headers: HttpHeaders) =
    ## Add headers to the HTTP response
    for k, v in headers:
        msg.add(k & ": " & v & "\c\L")

proc buildHTTPResponse(code: HttpCode, content: string,
              headers: HttpHeaders = nil): string =
    ## Build the full HTTP response
    var msg = "HTTP/1.1 " & $code & "\c\L"

    if headers != nil:
        msg.addHeaders(headers)

    # If the headers did not contain a Content-Length use our own
    if headers.isNil() or not headers.hasKey("Content-Length"):
        msg.add("Content-Length: ")
    # this particular way saves allocations:
    msg.addInt content.len
    msg.add "\c\L"

    msg.add "\c\L"
    msg.add content
    return msg

proc startHttpServer(s: HttpServer) {.thread.} =
    ## Thread procedure - starts the HTTP server and handles the
    ## incoming requests
    # Socket init
    var socket = newSocket()
    socket.setSockOpt(OptReuseAddr, true)
    socket.bindAddr(Port(s.port))
    socket.listen()
    print("loading", "Listening on port: " & $(s.port))
    
    # Check incoming connections
    while true:
        var 
            client: net.Socket
            address = ""
            rec = ""
            msg = ""
            requestedFile = ""
            stop = false
            response = ""
        socket.acceptAddr(client, address)
        inWorking = true
        while not stop:
            try:
                rec = client.recvLine(timeout=1000)
                # Check if stop
                if rec.contains("stop") and address == "127.0.0.1":
                    print("loading", "Server stopped")
                    socket.close()
                    s.status = false
                    return
                if rec.contains("GET"):
                    requestedFile = rec.split("GET /")[1]
                    requestedFile = requestedFile.split("HTTP")[0].strip()
                    print("loading", address & " requested: " & requestedFile)
                msg &= "\n" & rec
            except:
                stop = true

        if validateFile(requestedFile):
            let content = readFile(requestedFile)
            response = $(buildHTTPResponse(Http200, content, newHttpHeaders()))
        else:
            response = $(buildHTTPResponse(Http404, "File not found", newHttpHeaders()))
        
        if client.trySend(response):
            discard
        client.close()
        inWorking = false


when isMainModule:
    # Starts the http server and runs it for 30 seconds with 15 second timeout
    let server = newHttpServer(8080, 15)
    server.start()
    sleep(30000)
