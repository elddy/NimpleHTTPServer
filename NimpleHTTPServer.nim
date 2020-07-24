#[
    Simple HTTP server with net sockets
    Compile only with: --threads:on --opt:speed
]#

# Imports
import net, asyncdispatch, asynchttpserver, strutils, os, times, terminal

# Type HTTPServer
type
  HTTPServer* = ref object of RootObj
    port: int
    timeout: float # in seconds
    status: bool

# In working http request
var 
    inWorking = false
    stopped = false

#[ 
    Declaration of functions
]#

# Initialize functions
proc timeout*(s: HTTPServer): float {.inline.}
proc `timeout=`*(s: var HTTPServer, value: float) {.inline.}
proc port*(s: HTTPServer): int {.inline.}
proc `port=`*(s: var HTTPServer, value: int) {.inline.}
proc status*(s: HTTPServer): bool {.inline.}
proc `status=`(s: HTTPServer, value: bool) {.inline.}

# Public functions
proc stopServer*(s: HTTPServer) {.inline.}
proc startServer*(s: HTTPServer) {.inline.}
proc joinServer*(s: HTTPServer): bool {.inline.}

# Private functions
proc timeOutStop(s: HTTPServer) {.thread.}
proc validateFile(file: string): bool
proc startHTTPServer(s: HTTPServer) {.thread.}

# Help functions
proc addHeaders(msg: var string, headers: HttpHeaders)
proc buildHTTPResponse(code: HttpCode, content: string, headers: HttpHeaders = nil): string

#[
    Init functions
]#
proc `port=`*(s: var HTTPServer, value: int) {.inline.} =
  ## setter of port
  s.port = value

proc port*(s: HTTPServer): int {.inline.} =
  ## getter of port
  s.port

proc `timeout=`*(s: var HTTPServer, value: float) {.inline.} =
  ## setter of timeout
  s.timeout = value

proc timeout*(s: HTTPServer): float {.inline.} =
  ## getter of timeout
  s.timeout

proc status*(s: HTTPServer): bool {.inline.} =
    ## getter of status
    s.status

proc `status=`(s: HTTPServer, value: bool) {.inline.} = 
    ## getter of status
    s.status = value

#[
    Print error or success with nice and colored output
]#
proc print(STATUS, text: string) =
    if STATUS == "error":
        stdout.styledWrite(fgRed, "[-] ")
    elif STATUS == "success":
        stdout.styledWrite(fgGreen, "[+] ")
    elif STATUS == "loading":
        stdout.styledWrite(fgBlue, "[*] ")
    elif STATUS == "warning":
        stdout.styledWrite(fgYellow, "[!] ")
    stdout.write(text & "\n")

#[
    Stops the server
]#
proc stopServer*(s: HTTPServer) {.inline.} =
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
    else:
        print("error", "The server is not running")

#[
    Stops the server thread if timeout declared
]#
proc timeOutStop(s: HTTPServer) {.thread.} =
    if s.timeout > 0:
        var runtime = cpuTime()
        while runTime < s.timeout:
            runtime = cpuTime() - runtime    
        s.stopServer()

#[
    Start the thread server
]#
proc startServer*(s: HTTPServer) {.inline.} =
    s.status = true
    # Start thread
    var thr: array[0..1, Thread[HTTPServer]]
    createThread(thr[0], startHTTPServer, s)
    createThread(thr[1], timeOutStop, s)
    sleep(1) # Needed

#[
    Stop everything and wait for the server to end
]#
proc joinServer*(s: HTTPServer): bool {.inline.} =
    if not s.status:
        print("error", "The server is not running")
        return false
    return joinServer(s)
    # while not stopped:
    #     continue

#[
    Validate file existence
]#
proc validateFile(file: string): bool =
    if existsFile(file):
        return true
    print("error", file & "not exist")
    return false

#[
    Help procedures
    ***************
]#

#[
    Add headers to http response
]#
proc addHeaders(msg: var string, headers: HttpHeaders) =
  for k, v in headers:
    msg.add(k & ": " & v & "\c\L")

#[
    Build full http response
]#
proc buildHTTPResponse(code: HttpCode, content: string,
              headers: HttpHeaders = nil): string =

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

#[
    Function thread.
    Starts the http server and handle the requests.
]#
proc startHTTPServer(s: HTTPServer) {.thread.} =

    # Socket init
    var socket = newSocket()
    socket = newSocket()
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
                    stopped = true
                    return
                if rec.contains("GET"):
                    requestedFile = rec.split("GET /")[1]
                    requestedFile = requestedFile.split("HTTP")[0]
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
                 




