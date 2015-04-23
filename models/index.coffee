Promise = require "bluebird"
glob = Promise.promisify(require "glob")
rfr = require "rfr"

# This file automatically loads all models.

module.exports = (shelf) ->
	Promise.try ->
		glob "models/**/*.coffee"
	.then (items) ->
		for item in items
			if item != "models/index.coffee"
				rfr(item)(shelf)
