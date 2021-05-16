Promise = require "bluebird"
router = require("express-promise-router")()
errors = require "errors"
busboy = require "../lib/connect-busboy/connect-busboy"

path = require "path"
fs = require "fs"

rfr = require "rfr"
config = rfr "config.json"
randomString = rfr "lib/random-string"
streamContains = rfr "lib/stream-contains"
tapError = rfr "lib/tap-error"
disableInMaintenanceMode = rfr "lib/disable-in-maintenance-mode"

router.post "/", disableInMaintenanceMode, busboy(limits: {fileSize: (config.upload_size_limit ? (150 * 1024 * 1024))}), (req, res) ->
	Promise.try ->
		Promise.all [
			randomString 16
			randomString 16
		]
	.spread (slugID, fileID) ->
		storagePath = path.join config.storage_path, fileID

		Promise.try ->
			handleUpload req, res, storagePath: storagePath, fieldName: "file"
		.then ->
			headStream = fs.createReadStream storagePath, end: 1023
			streamContains headStream, "%PDF"
		.then (isPDF) ->
			if isPDF
				Promise.resolve()
			else
				Promise.reject new errors.InvalidFiletype "The file you uploaded is not a valid PDF file."
		.then ->
			objData =
				SlugId: slugID
				Public: (req.body.visibility == "public")
				Views: 0
				OriginalFilename: req.files.file.filename
				Filename: fileID
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

handleUpload = (req, res, options) ->
	if not req.busboy?
		return Promise.resolve()
	else
		return new Promise (resolve, reject) ->
			processFields req, res, options
			processFiles req, res, options

			req.busboy.on "finish", ->
				resolve()

			req.pipe req.busboy

processFields = (req, res, options) ->
	req.body ?= {}

	req.busboy.on "field", (name, value, keyTruncated, valueTruncated) ->
		req.body[name] = value

processFiles = (req, res, options) ->
	req.busboy.on "file", (name, file, filename, encoding, mimetype) ->
		# TODO: Is the encoding taken care of automatically...?
		if name != options.fieldName
			# This is not the correct form field. Ignore it.
			return

		file
			.on "limit", ->
				# The maximum file size was exceeded.
				file.unpipe()
				reject new errors.UploadTooLarge "The file you attempted to upload is too large."
			.pipe fs.createWriteStream(options.storagePath)

		req.files ?= {}

		req.files[name] =
			filename: filename
			encoding: encoding
			mimetype: mimetype
			storagePath: options.storagePath

module.exports = router
