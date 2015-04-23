# Update with your config settings.

config = require "./config.json"

module.exports =
	# TODO: Do we need an environment name here?
	development:
		client: "mysql2"
		connection:
			database: config.database.database
			user: config.database.username
			password: config.database.password
		pool:
			min: 2
			max: 10
		migrations:
			tableName: "knex_migrations"
