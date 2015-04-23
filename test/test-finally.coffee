Promise = require "bluebird"
tapError = require "../lib/tap-error"

Promise.try ->
	return 42
.then ->
	#return 84
	throw new Error "test"
.finally (val) ->
	console.log "finally", val
.catch tapError (err) ->
	console.log "tap-err", err.stack
	Promise.delay(1000)
.then (val) ->
	console.log "then", val
.catch (err) ->
	console.log "catch", err.stack
