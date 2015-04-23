Promise = require "bluebird"

module.exports = (shelf) ->
	shelf.model "BlogPost",
		tableName: "blog_posts"
		idAttribute: "Id"
