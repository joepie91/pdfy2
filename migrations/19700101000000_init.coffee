
exports.up = (knex, Promise) ->
	knex.schema.createTable "documents", (table) ->
        table.bigIncrements("Id").primary()
        table.string("SlugId", 16)
        table.string("Filename", 120)
        table.boolean("Public")
        table.string("DeleteKey", 32)
        table.bigInteger("Views")
        table.string("OriginalFilename", 256)
        table.timestamp("Uploaded")
        table.boolean("Mirrored")

exports.down = (knex, Promise) ->
	knex.schema.dropTable "documents"
