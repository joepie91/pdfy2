class RateLimiter
	constructor: (@limit, @interval, @funcA, @funcB) ->
		@_totalCalls = 0
		@_startTimer()
	_startTimer: ->
		@_timer = setInterval @_clearCalls, @interval
	_stopTimer: ->
		if @_timer?
			clearInterval @_timer
			@_timer = null
	_clearCalls: ->
		@_totalCalls = 0
	call: ->
		@_totalCalls += 1

		targetFunc = switch
			when @_totalCalls <= @limit then @funcA
			else @funcB

		targetFunc.apply this, arguments
	setInterval: (interval) ->
		@_stopTimer()
		@interval = interval
		@_startTimer()
	setLimit: (limit) ->
		@limit = limit

module.exports = ->
	return (funcA, funcB, options) ->
		if not options.limit?
			throw new Error("No limit specified.")
		options.interval ?= 60 # Default: 60 seconds ie. 1 minute.

		return new RateLimiter(options.limit, options.interval, funcA, funcB)
