Promise = require "bluebird"
crypto = Promise.promisifyAll(require "crypto")

module.exports = (length = 16) ->
	Promise.try ->
		byteLength = Math.ceil(length / 4) * 3
		return crypto.randomBytesAsync(byteLength)
	.then (bytes) ->
		bytes = bytes
			.toString "base64"
			.replace /\+/g, "-"
			.replace /\//g, "_"
			.slice 0, length

		Promise.resolve bytes
