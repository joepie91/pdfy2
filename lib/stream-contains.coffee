Promise = require "bluebird"
concatStream = require "concat-stream"

module.exports = (stream, needle) ->
	# CAUTION: This buffers up in memory!
	new Promise (resolve, reject) ->
		stream
			.pipe concatStream (result) ->
				resolve result.indexOf(result, needle) != -1
			.on "error", (err) ->
				reject err
