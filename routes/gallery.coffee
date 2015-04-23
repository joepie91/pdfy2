router = require("express-promise-router")()
Promise = require "bluebird"
moment = require "moment"
errors = require "errors"

router.get "/:page?", (req, res) ->
	Promise.try ->
		if req.params.page? and  /^[0-9]+$/.exec(req.params.page) == null
			throw new errors.InvalidInput("The specified page number is not valid.")

		documentsPerPage = req.appConfig.display.documentsPerPage.gallery

		if req.params.page?
			pageNumber = parseInt(req.params.page) - 1

			if isNaN pageNumber
				pageNumber = 0
		else
			pageNumber = 0

		start = documentsPerPage * pageNumber

		Promise.try ->
			Promise.all [
				req.modelQuery "Document", (qb) ->
					qb.where "Public": 1, "Disabled": 0
					.orderBy "Uploaded", "desc"
					.offset start
					.limit documentsPerPage
				.retrieveAll([], require: false),

				req.model("Document").countAllWhere "Public": 1
			]
		.spread (documents, documentCount) ->
			documents.forEach (document) ->
				# TODO: There must be a nicer way to do this.
				document.set "Uploaded", moment(document.get("Uploaded")).format "MMMM Do, YYYY hh:mm:ss"

			res.render "gallery",
				documents: documents.toJSON()
				pageNumber: pageNumber
				pageCount: Math.ceil(documentCount / documentsPerPage)

module.exports = router
