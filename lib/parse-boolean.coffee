module.exports = (param) ->
	if not param?
		return undefined
	else
		return !!(parseInt(param))