Promise = require "bluebird"
router = require("express-promise-router")()
errors = require "errors"
moment = require "moment"

path = require "path"

rfr = require "rfr"
parseBoolean = rfr "lib/parse-boolean"
config = rfr "config.json"

router.param "documentSlug", (req, res, next, documentSlug) ->
	Promise.try ->
		req.model("Document").getOneWhere SlugId: documentSlug
	.then (document) ->
		req.document = document

		if document.get("Public") != 1
			res.append "X-Robots-Tag", "noindex"

		next()
	.catch req.db.NotFoundError, (err) ->
		next new errors.Http404Error "No such document exists."

router.get "/:documentSlug", (req, res) ->
	Promise.try ->
		if req.document.get "Disabled"
			res.locals.abuseReason = true

			Promise.reject new errors.Http403Error
				message: "This document is not available."
				subMessage: "It may have been removed for violation of the Terms of Service, or on request of the uploader."
				explanation: req.document.get "DisabledReason"
		else
			documentData = req.document.toJSON()
			documentData.Uploaded = moment(req.document.get("Uploaded")).format "MMM Do, YYYY hh:mm:ss"

			res.render "view",
				document: documentData
				currentMonth: moment().format "MMMM YYYY"

router.get "/:documentSlug/embed", (req, res) ->
	Promise.try ->
		res.locals.compactLayout = true

		if req.document.get "Disabled"
			res.locals.abuseReason = true

			Promise.reject new errors.Http403Error
				message: "This document is not available."
				subMessage: "It may have been removed for violation of the Terms of Service, or on request of the uploader."
				explanation: req.document.get("DisabledReason")
		else
			# We want our update to be atomic, so we can't use the default model, and need to construct a Knex query instead.
			req.model("Document").query()
				.where SlugId: req.params.documentSlug
				.increment "Views"
				.catch (err) ->
					# An error here is not very important - we'll log it still, but we won't need to abort the request.
					req.reportError(err)

			res.render "embed",
				document: req.document.toJSON()
				sparse: parseBoolean(req.query.sparse) ? false
				footer: parseBoolean(req.query.footer) ? true
				showDonationLink: parseBoolean(req.query.donation_link) ? false
				url: "/d/#{req.document.toJSON().SlugId}/download"

router.get "/:documentSlug/download", (req, res) ->
	Promise.try ->
		if req.document.get "Disabled"
			res.locals.abuseReason = true

			Promise.reject new errors.Http403Error
				message: "This document is not available."
				subMessage: "It may have been removed for violation of the Terms of Service, or on request of the uploader."
				explanation: req.document.get("DisabledReason")
		else
			document = req.document.toJSON()
			res.download path.join(config.storage_path, document.Filename), document.OriginalFilename

module.exports = router
