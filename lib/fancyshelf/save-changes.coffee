_ = require "lodash"
Promise = require "bluebird"

module.exports = (bookshelf) ->
	bookshelf.Model.prototype.saveChanges = (options = {}) ->
		# This fails silently if nothing has changed. Really, bookshelf should be checking
		# for this case when 'changed' is empty, but it doesn't - it'll just construct an
		# invalid SQL query.
		if not _.isEmpty(@changed)
			options.patch = true
			@save @changed, options
		else
			Promise.resolve(this)
