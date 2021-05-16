express = require('express')
uuid = require "uuid"
fs = require "fs"
domain = require "domain"

app = express()

reportError = (err, type = "error", sync = false) ->
	if err.code == "ECONNRESET"
		# We're not interested in these for now, they're just aborted requests.
		# TODO: Investigate whether there may also be other scenarios where an ECONNRESET is raised.
		return

	errorPayload = {}

	Object.getOwnPropertyNames(err).forEach (key) ->
		errorPayload[key] = err[key]

	filename = "errors/#{type}-#{Date.now()}-#{uuid.v4()}.json"

	if sync
		fs.writeFileSync filename, JSON.stringify(errorPayload)
	else
		fs.writeFile filename, JSON.stringify(errorPayload)

# To make absolutely sure that we can log and exit on all uncaught errors.
if app.get("env") == "production"
	logAndExit = (err) ->
		reportError(err, "error", true)
		process.exit(1)

	rootDomain = domain.create()
	rootDomain.on "error", logAndExit

	runWrapper = (func) ->
		rootDomain.run ->
			try
				func()
			catch err
				logAndExit(err)
else
	# In development, we don't have to catch uncaught errors. Just run the specified function directly.
	runWrapper = (func) -> func()

runWrapper ->
	path = require('path')

	favicon = require('serve-favicon')
	logger = require('morgan')
	cookieParser = require('cookie-parser')
	bodyParser = require('body-parser')
	fancyshelf = require "fancyshelf"
	session = require "express-session"
	csurf = require "csurf"
	fileStreamRotator = require "file-stream-rotator"
	domainMiddleware = require("express-domain-middleware")

	errors = require "errors"
	PrettyError = require "pretty-error"
	Convert = require "ansi-to-html"
	marked = require "marked"
	moment = require "moment"

	persist = require "./lib/persist"
	useCsrf = require "./lib/use-csrf"
	templateUtil = require("./lib/template-util")
	sessionStore = require("./lib/persist-session")(session)

	config = require "./config.json"
	knexfile = require("./knexfile").development

	ansiHTML = new Convert(escapeXML: true, newline: true)

	# Error handling
	pe = PrettyError.start()
	pe.skipPackage "bluebird", "coffee-script", "express", "express-promise-router", "pug"
	pe.skipNodeFiles()

	errors.create
		name: "UploadError"

	errors.create
		name: "UploadTooLarge"
		parents: errors.UploadError
		status: 413

	errors.create
		name: "InvalidFiletype"
		parents: errors.UploadError
		status: 415

	errors.create
		name: "NotAuthenticated"
		status: 403

	errors.create
		name: "InvalidInput"
		status: 422

	# Database setup
	shelf = fancyshelf
		engine: knexfile.client
		host: knexfile.connection.host
		username: knexfile.connection.user
		password: knexfile.connection.password
		database: knexfile.connection.database
		debug: (app.get("env") == "development")

	# Task runner
	TaskRunner = require("./lib/task-runner")
	runner = new TaskRunner(app: app, db: shelf, config: config, thumbnailPath: path.join(__dirname, 'thumbnails'))
	runner.addTask "mirror", require("./tasks/mirror"), maxConcurrency: 5
	runner.addTask "thumbnail", require("./tasks/thumbnail")
	runner.run()

	runner.on "taskQueued", (taskType, task) ->
		persist.increment "task:#{taskType}:queued"

	runner.on "taskStarted", (taskType, task) ->
		persist.decrement "task:#{taskType}:queued"
		persist.increment "task:#{taskType}:running"

	runner.on "taskFailed", (taskType, task) ->
		persist.decrement "task:#{taskType}:running"
		persist.increment "task:#{taskType}:failed"

	runner.on "taskCompleted", (taskType, task) ->
		persist.decrement "task:#{taskType}:running"
		persist.increment "task:#{taskType}:completed"

	if app.get("env") == "development"
		runner.on "taskFailed", (taskType, task, err) ->
			console.log err.stack
	else
		runner.on "taskFailed", (taskType, task, err) ->
			reportError err, "taskFailed"

	# Configure Express
	app.set('views', path.join(__dirname, 'views'))
	app.set('view engine', 'pug')

	# Middleware
	if app.get("env") == "development"
		app.use(logger('dev'))
	else
		accessLogStream = fileStreamRotator.getStream frequency: (config.accessLog.frequency ? "24h"), filename: config.accessLog.filename
		app.use logger (config.accessLog.format ? "combined"), stream: accessLogStream

	app.use (req, res, next) ->
		if config.ssl?.key?
			if req.secure
				res.set "Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload"
				next()
			else
				res.redirect "https://pdf.yt/"
		else
			next()

	# Using /static/ paths to maintain backwards compatibility.
	app.use("/static/thumbs", express.static(path.join(__dirname, 'thumbnails')))
	app.use("/static/pdfjs", express.static(path.join(__dirname, 'public/pdfjs')))
	app.use(express.static(path.join(__dirname, 'public')))
	#app.use(favicon(__dirname + '/public/favicon.ico'))

	app.use domainMiddleware
	app.use templateUtil
	app.use shelf.express

	app.use session
		store: new sessionStore
			persist: persist
		secret: config.session.signingKey
		resave: true # TODO: Implement `touch` for the session store, and/or switch to a different store.
		saveUninitialized: false

	# Load models
	require("./models")(shelf)

	app.use(bodyParser.json())
	app.use(bodyParser.urlencoded({ extended: false }))
	app.use(cookieParser())

	app.use (req, res, next) ->
		res.locals.md = marked

		req.appConfig = config
		req.persist = persist

		jadeExports = [
			"announcementVisible"
			"announcementText"
			"announcementLinkText"
			"announcementLink"
			"maintenanceMode"
			"maintenanceModeText"
			"donationGoal"
			"donationTotal"
			"showNotice"
		]

		for key in jadeExports
			res.locals[key] = persist.getItem "var:#{key}"

		res.locals.bitcoinAddress = config.donations.bitcoinAddress
		res.locals.isAdmin = req.session.isAdmin

		# This is for logging/reporting errors that should not occur, but that are known to not cause any adverse side-effects.
		# This should NOT be used for errors that could leave the application in an undefined state!
		req.reportError = reportError

		req.taskRunner = runner

		next()

	app.use "/", require("./routes/index")
	app.use "/donate", require("./routes/donate")
	app.use "/d", require("./routes/document")
	app.use "/upload", require("./routes/upload")
	app.use "/gallery", require("./routes/gallery")
	app.use "/blog", require("./routes/blog")
	app.use "/admin", csurf(), useCsrf, require("./routes/admin")

	# If no routes match, cause a 404
	app.use (req, res, next) ->
		next new errors.Http404Error("The requested page was not found.")

	# Error handling middleware
	app.use "/static/thumbs", (err, req, res, next) ->
		# TODO: For some reason, Chrome doesn't always display images that are sent with a 404 status code. Let's stick with 200 for now...
		#res.status 404
		if err.status == '404'
			fs.createReadStream path.join(__dirname, "public/images/no-thumbnail.png")
				.pipe res
		else
			next(err)

	app.use (err, req, res, next) ->
		statusCode = err.status || 500
		res.status(statusCode)

		# Dump the error to disk if it's a 500, so that the error reporter can deal with it.
		if app.get("env") != "development" and statusCode == 500
			reportError(err)

		# Display the error to the user - amount of details depending on whether the application is running in production mode or not.
		if (app.get('env') == 'development')
			stack = err
		else
			if statusCode == 500
				errorMessage = "An unknown error occurred."
				stack = {stack: "An administrator has been notified, and the error will be resolved as soon as possible. Apologies for the inconvenience."}
			else
				errorMessage = err.message
				stack = {stack: err.explanation, subMessage: err.subMessage}

		if req.headers["X-Requested-With"] == "XMLHttpRequest"
			res.send {
				message: errorMessage,
				error: stack
			}
		else
			if err instanceof errors.NotAuthenticated
				res.redirect "/admin/login"
			else
				if app.get("env") == "development"
					htmlStack = ansiHTML.toHtml(stack.stack)
						.replace /#555/g, "#b5b5b5"

				# TODO: It seems aborted responses will result in an attempt to send an error page/header - of course this can't succeed, as the headers have already been sent by that time, and an error is thrown.
				res.render('error', {
					message: errorMessage,
					error: stack,
					statusCode: statusCode,
					htmlStack: htmlStack
				})


module.exports = app
