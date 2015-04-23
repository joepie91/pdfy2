Promise = require "bluebird"
concatStream = require "concat-stream"
buffertools = require "buffertools"

module.exports = (stream, needle) ->
	# CAUTION: This buffers up in memory!
	new Promise (resolve, reject) ->
		stream
			.pipe concatStream (result) ->
				resolve buffertools.indexOf(result, needle) != -1
			.on "error", (err) ->
				reject err
