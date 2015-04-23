Promise = require "bluebird"
bhttp = require "bhttp"

lastRates = null
lastRateCheck = 0

module.exports = ->
	Promise.try ->
		if Date.now() > lastRateCheck + (5 * 60 * 1000)
			# We need fresh API data, 5 minutes have elapsed.
			Promise.try ->
				Promise.all [
					bhttp.get "http://api.fixer.io/latest", decodeJSON: true
					bhttp.get "https://blockchain.info/ticker", decodeJSON: true
				]
			.spread (fixerRates, blockchainRates) ->
				eurRates = fixerRates.body.rates
				eurRates.BTC = 1 / blockchainRates.body.EUR["15m"]
				Promise.resolve eurRates
			.then (rates) ->
				lastRates = rates
				lastRateCheck = Date.now()
				Promise.resolve rates
		else
			Promise.resolve lastRates
