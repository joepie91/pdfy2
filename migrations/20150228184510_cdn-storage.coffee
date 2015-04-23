
exports.up = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.boolean "CDN"

exports.down = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.dropColumn "CDN"
