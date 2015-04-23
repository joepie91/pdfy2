
exports.up = (knex, Promise) ->
	knex.schema.createTable "blog_posts", (table) ->
		table.bigIncrements("Id")
		table.string("Slug")
		table.string("Title")
		table.text("Body", "longtext")
		table.timestamp("Posted").nullable()
		table.timestamp("Edited").nullable()


exports.down = (knex, Promise) ->
	knex.schema.dropTable "blog_posts"
