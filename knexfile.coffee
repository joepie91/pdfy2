# Update with your config settings.

config = require "./config.json"

module.exports =
	development:
		client: config.database.client ? "mysql2"
		connection:
			database: config.database.database
			user: config.database.username
			password: config.database.password
		pool:
			min: 2
			max: 10
		migrations:
			tableName: "knex_migrations"
