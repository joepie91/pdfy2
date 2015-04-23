router = require("express-promise-router")()
Promise = require "bluebird"
errors = require "errors"
rfr = require "rfr"
config = rfr "config.json"

router.param "documentSlug", (req, res, next, documentSlug) ->
	Promise.try ->
		req.model("Document").getOneWhere SlugId: documentSlug
	.then (document) ->
		req.document = document
		next()
	.catch req.db.NotFoundError, (err) ->
		next new errors.Http404Error "No such document exists."

router.get "/", (req, res) ->
	Promise.try ->
		req.model("Document").getAllFromQuery (queryBuilder) ->
			queryBuilder
				.where "Public": 1, Disabled: 0
				.orderBy "Uploaded", "desc"
				.limit 6
	.then (latestDocuments) ->
		res.render "index",
			latestDocuments: latestDocuments.toJSON()

router.get "/tos", (req, res) ->
	res.render "tos"

router.get "/abuse", (req, res) ->
	res.render "abuse"

router.get "/faq", (req, res) ->
	res.render "faq"

module.exports = router
