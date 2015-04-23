
exports.up = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.string "DisabledReason"
			.nullable()

exports.down = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		table.dropColumn "DisabledReason"
