Promise = require "bluebird"
router = require("express-promise-router")()
moment = require "moment"
slug = require "slug"
scrypt = require "scrypt-kdf"

rfr = require "rfr"
config = rfr "config"
authMiddleware = rfr "lib/middleware-auth"
useCsrf = rfr "lib/use-csrf"
persist = rfr "lib/persist"

rateLimit = require "express-rate-limit"
loginRateLimit = rateLimit({windowMs: 60*60*1000, max: 5, message: "Uh uh uh, naughty naughty naughty."})

# Routes

router.get "/login", (req, res) ->
	res.render "admin/login"

router.post "/login", loginRateLimit, (req, res) ->
	Promise.try ->
		scrypt.verify(Buffer.from(config.admin.hash, 'base64'), req.body.password)
	.then (success) ->
		if ( success )
			if req.body.username == config.admin.username
				req.session.isAdmin = true
				res.redirect "/admin"
			else
				res.redirect "/admin"
		else
			res.redirect "/admin/login"

router.post "/logout", authMiddleware, (req, res) ->
	delete req.session.isAdmin
	res.redirect "/"

router.get "/", authMiddleware, (req, res) ->
	Promise.try ->
		req.model("BlogPost").getAll()
	.then (blogPosts) ->
		variables = req.persist.getItem("variableTypes")
			.map (type) ->
				return {
					key: type.name
					type: type.type
					value: req.persist.getItem("var:#{type.name}")
				}
			.sort (one, other) ->
				if one.key > other.key
					return 1
				else
					return -1

		taskTypes = req.persist.getItem "taskTypes"
			.map (type) ->
				return {
					name: type
					running: req.persist.getItem "task:#{type}:running"
					queued: req.persist.getItem "task:#{type}:queued"
					failed: req.persist.getItem "task:#{type}:failed"
					completed: req.persist.getItem "task:#{type}:completed"
				}

		res.render "admin/index",
			variables: variables
			taskTypes: taskTypes
			blogPosts: blogPosts.toJSON()

router.post "/variables", authMiddleware, (req, res) ->
	Promise.try ->
		req.persist.getItem("variableTypes")
	.map (variable) ->
		key = variable.name

		value = switch variable.type
			when "boolean" then req.body[key]?
			when "text", "string" then req.body[key].toString()
			when "number" then parseFloat(req.body[key])

		req.persist.setItem "var:#{key}", value
	.then ->
		res.redirect "/admin"

router.post "/search", authMiddleware, (req, res) ->
	Promise.try ->
		switch req.body.field
			when "slug"
				req.model("Document").getAllWhere "SlugId": req.body.query, [], require: false
			when "filename"
				req.model("Document").query (qb) ->
					qb.where "OriginalFilename", "like", "%#{req.body.query}%"
				.fetchAll(require: false)
	.then (results) ->
		results = results.map (result) ->
			resultObject = result.toJSON()
			resultObject.Uploaded = moment(result.get("Uploaded")).format "MMM Do, YYYY hh:mm:ss"
			return resultObject

		res.render "admin/search", results: results

router.post "/documents", authMiddleware, (req, res) ->
	Promise.try ->
		Object.keys(req.body)
			.map (item) -> /^document\[([0-9]+)\]$/.exec(item)?[1]
			.filter (item) -> item?
			.map (item) -> parseInt item
	.map (documentId) ->
		req.model("Document").find documentId
	.map (document) ->
		switch req.body.action
			when "public" then document.set("Public": 1).saveChanges()
			when "private" then document.set("Public": 0).saveChanges()
			when "thumbnail" then req.taskRunner.do "thumbnail", id: document.get("SlugId")
			when "mirror" then req.taskRunner.do "mirror", id: document.get("SlugId")
			when "restore" then document.set("Disabled": 0).saveChanges()
			when "abuse"
				abuseReason = req.body.abuseReason
				if not abuseReason? or abuseReason.trim?()?.length == 0
					abuseReason = null
				document.set("Disabled": 1, "DisabledReason": abuseReason).saveChanges()
	.then (documents) ->
		res.redirect "/admin"

router.get "/blog/new", authMiddleware, (req, res) ->
	res.render "admin/blog", post: {}

router.get "/blog/delete/:id", authMiddleware, (req, res) ->
	Promise.try ->
		req.model("BlogPost").find(req.params.id)
	.then (post) ->
		res.render "admin/blog-delete", post: post.toJSON()

router.post "/blog/delete/:id", authMiddleware, (req, res) ->
	Promise.try ->
		req.model("BlogPost").find(req.params.id)
	.then (post) ->
		post.destroy()
	.then ->
		res.redirect "/admin"

router.get "/blog/edit/:id", authMiddleware, (req, res) ->
	Promise.try ->
		req.model("BlogPost").find(req.params.id)
	.then (post) ->
		res.render "admin/blog", post: post.toJSON()

router.post "/blog/edit/:id?", authMiddleware, (req, res) ->
	Promise.try ->
		if req.params.id?
			req.model("BlogPost").find(req.params.id)
		else
			req.model("BlogPost").forge()
	.then (post) ->
		post.set
			Title: req.body.title
			Body: req.body.body
			Edited: new Date()

		if post.isNew()
			post.set
				Posted: new Date()
				Slug: slug(req.body.title)

		post.save()
	.then ->
		res.redirect "/admin"

module.exports = router
