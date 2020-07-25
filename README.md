# NimpleHTTPServer
SimpleHTTPServer module for Nim - **For Files Only**

## Install
```
nimble install https://github.com/Hydra820/NimpleHTTPServer
```

## Usage
```Nim
import NimpleHTTPServer
```

## Examples
Start and stop server as you like:
```Nim
import NimpleHTTPServer

var server: HTTPServer
new server

# Init server. Didn't set timeout means the server will run forever
server.port = 80

server.startServer() # Start the server as a thread

# Do what you want

# You can check server status
echo server.status # prints true if running

server.stopServer() # Stop the server and close the socket
```

Set timeout to the server:
```Nim
import NimpleHTTPServer

var server: HTTPServer
new server

# Init server
server.port = 80
server.timeout = 3 # In seconds

server.startServer() # Start the server as a thread

# Do what you want
# After 3 seconds...
# Server stopped automatically
```

Join the server thread:
```Nim
import NimpleHTTPServer

var server: HTTPServer
new server

# Init server
server.port = 80
server.timeout = 3 # In seconds

server.startServer() # Start the server as a thread

# Do what you want

server.joinServer() # Stop everything and wait for the server
```

## Compile
Compile only with:
```
--threads:on --opt:speed
```
