
exports.up = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.boolean "Thumbnailed"

exports.down = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.dropColumn "Thumbnailed"
