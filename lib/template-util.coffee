moment = require "moment"

module.exports = (req, res, next) ->
	res.locals.conditionalClasses = (always, conditionals) ->
		applicableConditionals = (className for className, condition of conditionals when condition)
		applicableClasses = always.concat applicableConditionals
		return applicableClasses.join " "

	res.locals.makeBreakable = (string) ->
		require("jade/lib/runtime").escape(string).replace(/_/g, "_<wbr>")

	res.locals.shortDate = (date) ->
		moment(date).format "MMM Do, YYYY hh:mm:ss"

	next()
