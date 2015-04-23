#!/usr/bin/env coffee

app = require('../app')
debug = require('debug')('pdfy:server')
http = require('http')

normalizePort = (val) ->
	port = parseInt val, 10

	if isNaN port
		return val

	if port >= 0
		return port

	return false

onError = (error) ->
	if error.syscall != "listen"
		throw error

	bind = if typeof port == "string"
		"Pipe #{port}"
	else
		"Port #{port}"

	switch error.code
		when "EACCES"
			console.error "#{bind} requires elevated privileges"
			process.exit 1
		when "EADDRINUSE"
			console.error "#{bind} is already in use"
			process.exit 1
		else
			throw error


onListening = ->
	addr = server.address()

	bind = if typeof port == "string"
		"pipe #{port}"
	else
		"port #{port}"

	debug("Listening on #{bind}")


port = normalizePort(process.env.PORT || '3000')
app.set('port', port)

server = http.createServer(app)

server.listen(port)
server.on('error', onError)
server.on('listening', onListening)
