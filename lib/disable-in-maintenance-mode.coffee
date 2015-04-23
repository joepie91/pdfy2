module.exports = (req, res, next) ->
	if (not res.locals.maintenanceMode) or req.session.isAdmin
		next()
	else
		res.status(503).send(res.locals.maintenanceModeText)
