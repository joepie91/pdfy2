module.exports = (bookshelf) ->
	# FIXME: Alias options.require to options.required?

	_processOptions = (withRelations, options) ->
		options.require ?= true
		if typeof withRelations == "string" then withRelations = [withRelations]
		options.withRelated = withRelations
		return options

	bookshelf.Model.prototype.retrieve = (withRelations = [], options = {}) ->
		return this.fetch(_processOptions(withRelations, options))

	bookshelf.Model.prototype.retrieveAll = (withRelations = [], options = {}) ->
		return this.fetchAll(_processOptions(withRelations, options))

	bookshelf.Model.prototype.retrieveOptional = (withRelations = [], options = {}) ->
		options.require = false
		return this.fetch(_processOptions(withRelations, options))

	bookshelf.Model.prototype.retrieveAllOptional = (withRelations = [], options = {}) ->
		options.require = false
		return this.fetchAll(_processOptions(withRelations, options))
