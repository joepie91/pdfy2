# This will break horribly in a multi-process setup! Don't do that!
# NOTE: Does not currently ensure writes.

module.exports = (session) ->
	class PersistSessionStore extends session.Store
		constructor: (options) ->
			@persist = options.persist

		get: (sid, callback) ->
			sessionData = @persist.getItem "session:#{sid}"
			process.nextTick ->
				callback(null, sessionData)

		set: (sid, sessionData, callback) ->
			sessionData.__lastAccess = Date.now()
			@persist.setItem "session:#{sid}", sessionData
			process.nextTick ->
				callback(null)

		destroy: (sid, session, callback) ->
			@persist.removeItem "session:#{sid}"
			process.nextTick ->
				callback(null)

		length: (callback) ->
			length = @persist.valuesWithKeyMatch(/^session:/).length
			process.nextTick ->
				callback(null, length)

		clear: (callback) ->
			@persist.keys()
				.filter (key) -> key.match(/^session:/)
				.forEach (key) ->
					@persist.removeItem key

			process.nextTick ->
				callback(null)

		# TODO: .touch

