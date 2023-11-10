Promise = require "bluebird"
router = require("express-promise-router")()
errors = require "errors"
multer = require "multer"
process = require "process"

path = require "path"
fs = require "fs"

rfr = require "rfr"
config = rfr "config.json"
randomString = rfr "lib/random-string"
streamContains = rfr "lib/stream-contains"
tapError = rfr "lib/tap-error"
disableInMaintenanceMode = rfr "lib/disable-in-maintenance-mode"

copyfile = Promise.promisify fs.copyFile

upload = multer
	limits:
		fileSize: config.upload_size_limit ? 150 * 1024 * 1024
	fileFilter: (req, file, cb) ->
		if file.mimetype != "application/pdf"
			cb new errors.InvalidFiletype("The file you uploaded has a mime type of #{file.mimetype}, not application/pdf."), false
		cb null, true
	storage: multer.diskStorage
		destination: (req, file, cb) ->
			fs.mkdir "/tmp/pdfy-#{process.pid}", (err) ->
				cb null, "/tmp/pdfy-#{process.pid}"
		filename: (req, file, cb) ->
			randomString 16
			.then (value) ->
				cb null, value

router.post "/", disableInMaintenanceMode, upload.single('file'), (req, res) ->
	Promise.try ->
		Promise.all [
			randomString 16
		]
	.spread (slugID) ->
		storagePath = path.join config.storage_path, req.file.filename

		Promise.try ->
			headStream = fs.createReadStream req.file.path, end: 1023
			streamContains headStream, "%PDF"
		.then (isPDF) ->
			if isPDF
				Promise.resolve()
			else
				Promise.reject new errors.InvalidFiletype "The file you uploaded is not a valid PDF file."
		.then ->
			copyfile req.file.path, path.resolve(config.storage_path, req.file.filename)
		.then ->
			objData =
				SlugId: slugID
				Public: (req.body.visibility == "public")
				Views: 0
				OriginalFilename: req.file.originalname
				Filename: req.file.filename
				Mirrored: 0
				CDN: 0
				Thumbnailed: 0
				Uploaded: new Date()
				DeleteKey: ""

			req.model("Document").forge objData
			.save()
		.then (model) ->
			if config.storage.ia and model.get("Public") == true
				req.taskRunner.do "mirror", id: slugID

			req.taskRunner.do "thumbnail", id: slugID

			res.json {redirect: "/d/#{slugID}"}
		.catch tapError (err) ->
			# This is like a .tap, but for errors - it removes the file that was just uploaded.
			fs.unlink storagePath, (err) ->
				if err
					req.reportError err

		# TODO (CDN) SPEC: Then: (tasks abstracted to task file)
		# * Create task: Tahoe-LAFS upload, update DB entry
		# * Check if all tasks completed; if yes, remove file (but only if config says local storage is disabled).

module.exports = router
