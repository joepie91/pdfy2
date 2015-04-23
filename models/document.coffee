Promise = require "bluebird"

module.exports = (shelf) ->
	shelf.model "Document",
		tableName: "documents"
		idAttribute: "Id"
