# NimpleHTTPServer
SimpleHTTPServer module for Nim

## Install
```
nimble install https://github.com/Hydra820/NimpleHTTPServer
```

## Usage
```Nim
import NimpleHTTPServer
```

## Examples
```Nim
import NimpleHTTPServer

var server: HTTPServer
new server

# Init server
server.port = 80
server.timeout = 3 # In seconds

s.startServer() # Start the server as a thread

# Do what you want
# After 3 seconds...
# Server stopped automatically
```
