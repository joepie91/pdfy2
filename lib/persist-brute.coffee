# NOTE: This module does not currently ensure correct writes. Callbacks are called immediately (but asynchronously).

AbstractClientStore = require "express-brute/lib/AbstractClientStore"

module.exports = class PersistBruteStore extends AbstractClientStore
	constructor: (options) ->
		@persist = options.persist
		@prefix = options.prefix ? "brute"

		@_timers = {}
		@_keyMatcher = new RegExp("^#{@prefix}:")

		@persist.keys()
			.filter (key) => key.match(@_keyMatcher)
			.forEach (key) =>
				@_createExpiryTimer key, @persist.getItem(key).expiry

	_createExpiryTimer: (key, expiry) ->
		@_removeExpiryTimer(key)

		ttl = expiry - Date.now()

		if ttl < 0
			@_createRemover(key)()
		else
			setTimeout @_createRemover(key), ttl

	_removeExpiryTimer: (key) ->
		if @_timers[key]?
			clearTimeout @_timers[key]
			delete @_timers[key]

	_createRemover: (key) ->
		return =>
			@_removeExpiryTimer(key)

			prefixedKey = "#{@prefix}:#{key}"

			# TODO: Error handling?
			@persist.removeItem prefixedKey

	set: (key, value, lifetime, callback) ->
		prefixedKey = "#{@prefix}:#{key}"
		expiry = (Date.now() + lifetime)

		@_createExpiryTimer key, expiry
		@persist.setItem prefixedKey, {value: value, expiry: expiry}, callback

		process.nextTick ->
			callback(null)

	get: (key, callback) ->
		prefixedKey = "#{@prefix}:#{key}"
		result = @persist.getItem(prefixedKey)
		value = result?.value

		# Normalize to dates if we're reading from disk-persisted data... on disk, they're saved as strings.
		if value?.firstRequest? and value?.firstRequest not instanceof Date
			value.firstRequest = new Date(value.firstRequest)

		if value?.lastRequest? and value?.lastRequest not instanceof Date
			value.lastRequest = new Date(value.lastRequest)

		process.nextTick ->
			callback(null, value)

	reset: (key, callback) ->
		# I don't really understand why this is called 'reset'. It's quite clearly a 'remove' function...
		@_createRemover(key)()
		process.nextTick ->
			callback(null)
