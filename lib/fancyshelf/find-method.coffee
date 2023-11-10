module.exports = (bookshelf) ->
	bookshelf.Model.find = (id, withRelations = [], options = {}) ->
		options.require ?= true

		model = new this();
		model.set(model.idAttribute, id)

		if options.query?
			model.query options.query

		return model.retrieve(withRelations, options)

	bookshelf.Model.findOptional = (id, withRelations = [], options = {}) ->
		options.require = false
		return bookshelf.Model.find.call(this, id, withRelations, options)
