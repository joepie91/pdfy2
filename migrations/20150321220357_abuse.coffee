
exports.up = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.boolean "Disabled"
			.defaultTo 0

exports.down = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.dropColumn "Disabled"
