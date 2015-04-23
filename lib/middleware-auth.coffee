errors = require "errors"

module.exports = (req, res, next) ->
	if req.session?.isAdmin?
		next()
	else
		next(new errors.NotAuthenticated("You are not logged in as an administrator."))
