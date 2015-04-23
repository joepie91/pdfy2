
exports.up = (knex, Promise) ->
	knex.schema.table "documents", (table) ->
		knex.schema.raw "ALTER TABLE documents ADD INDEX (Public)"


exports.down = (knex, Promise) ->
	#
