# NOTE: This is purely a `tap` equivalent for errors! Any resolves or rejections are ignored - promises can only be used to wait for async execution of something.

Promise = require "bluebird"

module.exports = (func) ->
	return (err) ->
		Promise.try ->
			func(err)
		.catch ->
			# Consume any errors
			Promise.resolve()
		.then ->
			Promise.reject(err)
