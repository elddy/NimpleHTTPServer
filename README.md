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

# Init server with port 8080. Didn't set timeout means the server will run forever
let server = newHttpServer(8080)

server.start() # Start the server as a thread

# Do what you want

# You can check server status
echo server.status # prints true if running

server.stop() # Stop the server and close the socket
```

Set timeout to the server:
```Nim
import NimpleHTTPServer

var server: HTTPServer
new server

# Init server with timeout of 3 seconds
let server = newHttpServer(8080, 3)

server.start() # Start the server as a thread

# Do what you want
# After 3 seconds...
# Server stopped automatically
```

Join the server thread:
```Nim
import NimpleHTTPServer

let server = newHttpServer(8080, 3)

server.start() # Start the server as a thread

# Do what you want

server.join() # Stop current thread and wait for the server
```

## Compile
Compile only with:
```
--threads:on --opt:speed
```
