#!/usr/bin/env coffee

app = require('../app')
debug = require('debug')('pdfy:server')
http = require('http')
https = require("https")
config = require "../config.json"
fs = require "fs"

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
	addr = httpServer.address()

	bind = if typeof port == "string"
		"pipe #{port}"
	else
		"port #{port}"

	debug("Listening on #{bind}")


port = normalizePort(process.env.PORT || '3000')
app.set('port', port)

httpServer = http.createServer(app)

httpServer.listen(port)
httpServer.on('error', onError)
httpServer.on('listening', onListening)

if config.ssl?.key?
	credentials = {key: fs.readFileSync(config.ssl.key)}

	if config.ssl.cert?
		credentials.cert = fs.readFileSync(config.ssl.cert)

	if config.ssl.ca?
		credentials.cert = fs.readFileSync(config.ssl.ca)

	if config.ssl.ciphers?
		credentials.ciphers = config.ssl.ciphers
	else
		credentials.ciphers = "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"}

	httpsServer = https.createServer(credentials, app)

	httpsServer.listen(443)
	httpsServer.on('error', onError)
	httpsServer.on('listening', onListening)
