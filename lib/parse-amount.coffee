errors = require "errors"

amountRegex = /^[0-9]+(?:\.[0-9]+)?$/

module.exports = (amount) ->
	parsedAmount = parseFloat(amount)

	if amountRegex.exec(amount) == null or isNaN(parsedAmount)
		throw new errors.InvalidInput("The specified amount is invalid.")

	return parsedAmount
