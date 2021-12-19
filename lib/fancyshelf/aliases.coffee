Promise = require "bluebird"

module.exports = (bookshelf) ->
	bookshelf.Model.prototype.json = bookshelf.Model.prototype.toJSON
	bookshelf.Collection.prototype.json = bookshelf.Collection.prototype.toJSON

	_preprocessOptions = (model, options) ->
		if options.start?
			model.query (builder) -> builder.offset(options.start)
			delete options.start

		if options.limit?
			model.query (builder) -> builder.limit(options.limit)
			delete options.limit

		return [model, options]

	# The following is for briefer CoffeeScript syntax, mostly.

	bookshelf.modelQuery = (model, func) ->
		return @model(model).forge({}).query(func)

	bookshelf.collectionQuery = (collection, func) ->
		return @collection(collection).forge({}).query(func)

	# *FromQuery methods

	bookshelf.Model.getOneFromQuery = (func, withRelations = [], options = {}) ->
		return @forge({}).query(func).retrieve(withRelations, options)

	bookshelf.Model.getAllFromQuery = (func, withRelations = [], options = {}) ->
		[model, options] = @_fancyshelfQueryAllFromQuery func, options
		return model.retrieveAll(withRelations, options)

	bookshelf.Model.countAllFromQuery = (func, options = {}) ->
		Promise.bind(this).then ->
			[model, options] = @_fancyshelfQueryAllFromQuery func, options
			# CAUTION: Side-effects!
			model.query().count("#{model.idAttribute} as CNT")
		.then (result) ->
			Promise.resolve result[0].CNT

	bookshelf.Model._fancyshelfQueryAllFromQuery = (func, options) ->
		model = @forge({}).query(func)
		return _preprocessOptions model, options

	# *Where methods

	bookshelf.Model.getOneWhere = (conditions, withRelations = [], options = {}) ->
		return @forge(conditions).retrieve(withRelations, options)

	bookshelf.Model.getAllWhere = (conditions, withRelations = [], options = {}) ->
		# Bookshelf does not currently respect forge-set attributes for fetchAll calls
		[model, options] = @_fancyshelfQueryAllWhere conditions, options
		return model.retrieveAll(withRelations, options)

	bookshelf.Model.countAllWhere = (conditions, options = {}) ->
		Promise.bind(this).then ->
			[model, options] = @_fancyshelfQueryAllWhere conditions, options
			# CAUTION: Side-effects!
			model.query().count("#{model.idAttribute} as CNT")
		.then (result) ->
			Promise.resolve result[0].CNT

	bookshelf.Model._fancyshelfQueryAllWhere = (conditions, options) ->
		model = @forge {}
		for key, value of conditions
			model = model.where key, value
		return _preprocessOptions model, options

	# *All methods

	bookshelf.Model.getAll = (withRelations = [], options = {}) ->
		# Defaults to "not required"
		[model, options] = @_fancyshelfQueryAll options
		return model.retrieveAll(withRelations, options)

	bookshelf.Model.countAll = (options = {}) ->
		Promise.bind(this).then ->
			[model, options] = @_fancyshelfQueryAll options
			# CAUTION: Side-effects!
			model.query().count("#{model.idAttribute} as CNT")
		.then (result) ->
			Promise.resolve result[0].CNT

	bookshelf.Model._fancyshelfQueryAll = (options) ->
		model = @forge({})
		options.require ?= false
		return _preprocessOptions model, options
