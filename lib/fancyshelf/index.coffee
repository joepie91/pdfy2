bookshelf = require("bookshelf")
knex = require("knex")
util = require "util"

module.exports = (config) ->
	conn = config.knex ? knex({
		client: switch config.engine
			when "pg", "postgres", "postgresql" then "pg"
			else (config.engine ? "mysql2")
		connection:
			host: config.host ? "localhost"
			user: config.username
			password: config.password
			database: config.database
			charset: config.charset ? "utf8"
		debug: config.debug ? false
	})

	shelf = bookshelf(conn)
	shelf.connection = conn

	shelf.plugin("registry")  # We use the original model registry plugin, no point in reproducing a wheel.
	shelf.plugin("virtuals")  # We need the virtuals plugin as well.

	shelf.plugin(require.resolve("./aliases"))
	shelf.plugin(require.resolve("./better-fetch"))
	shelf.plugin(require.resolve("./find-method"))
	shelf.plugin(require.resolve("./retrieve-each"))
	shelf.plugin(require.resolve("./save-changes"))

	shelf.express = (req, res, next) ->
		req.db = shelf
		req.model = shelf.model.bind(shelf)
		req.modelQuery = shelf.modelQuery.bind(shelf)
		next()

	return shelf
