# TODO: Very unfinished! What did I even want to do with this?

module.exports = (bookshelf) ->
	bookshelf.Model.prototype.retrieveEach = (withRelated, options, callback) ->
		# Yes, I know, this violates the promises concept. It appears to be the only
		# way to make this cleanly usable, since promises can only resolve once. The
		# method will still return a promise, that resolves after all resulting rows
		# have been iterated through.
		collection = this.constructor.collection()
		collection._knex = this.query().clone()
		this.resetQuery()
		collection.relatedData = this.relatedData if this.relatedData?
		model = this

		collection.fetchOne()
			.then (model) ->
				console.log(model)
				return collection.fetchOne()
			.then (model) ->
				console.log(model)
