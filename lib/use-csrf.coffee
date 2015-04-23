module.exports = (req, res, next) ->
	token = req.csrfToken()
	res.locals.csrfToken = token
	next()
