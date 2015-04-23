Promise = require "bluebird"
router = require("express-promise-router")()
moment = require "moment"
marked = require "marked"
slug = require "slug"

mdRenderer = new marked.Renderer()
mdRenderer.heading = (text, level) ->
	sluggedText = slug(text).replace(/\./g, "-")

	return """
		<h#{level + 2}>
			<a name="#{sluggedText}" class="anchor" href="##{sluggedText}">
				§
			</a>
			#{text}
		</h#{level + 2}>
	"""

router.get "/", (req, res) ->
	Promise.try ->
		req.model("BlogPost").getAll()
	.then (blogPosts) ->
		blogPosts.forEach (post) ->
			# TODO: There must be a nicer way to do this. Maybe in yaorm.
			post.set "Posted", moment(post.get("Posted")).format "D MMM YYYY"

		res.render "blog-index", posts: blogPosts.toJSON()

router.get "/:articleID/:slug?", (req, res) ->
	Promise.try ->
		req.model("BlogPost").find(req.params.articleID)
	.then (post) ->
		post.set "HTML", marked(post.get("Body"), renderer: mdRenderer)
		res.render "blog-post", post: post.toJSON()

module.exports = router
