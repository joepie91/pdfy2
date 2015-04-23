fs = require "fs"
path = require "path"
Promise = require "bluebird"
_ = require "lodash"
iaHeaders = require "ia-headers"
moment = require "moment"
streamLength = require "stream-length"
bhttp = require "bhttp"
debug = require("debug")("pdfy:task:mirror")

retryTimeout = 20 * 1000

retryTask = (task, context) ->
	debug("received 'Slow Down' from IA, rescheduling upload in #{retryTimeout / 1000} seconds...")
	return new Promise (resolve, reject) ->
		setTimeout (->
			runTask task, context
				.then (result) -> resolve(result)
				.catch (err) -> reject(err)
		), retryTimeout

runTask = (task, context) ->
	Promise.try ->
		context.db.model("Document").getOneWhere SlugId: task.id
	.then (document) ->
		task.document = document

		if document.get("Public") != 1
			return Promise.reject new Error "Unlisted documents cannot be mirrored."

		task.stream = fs.createReadStream path.join(context.config.storage_path, document.get('Filename'))
		Promise.all [
			streamLength task.stream
			bhttp.get "http://s3.us.archive.org/?check_limit=1", decodeJSON: true
		]
	.spread (filesize, limitResponse) ->
		if limitResponse.body.over_limit == 1
			retryTask task, context
		else
			Promise.try ->
				uploadDate = moment(task.document.get 'Uploaded')
				if context.config.ia.collection == "test_collection"
					# This is to make sure that we can repeatedly test with the same document while developing, without clobbering the same identifier over and over again.
					slug = "#{task.document.get 'SlugId'}-#{Math.round(Math.random() * 1000000)}"
				else
					slug = task.document.get "SlugId"

				identifier = "pdfy-#{slug}"

				metadata =
					subject: ["mirror", "pdf.yt"]
					mediatype: "texts"
					collection: context.config.ia.collection
					date: uploadDate.format 'YYYY-MM-DD'
					title: "#{task.document.get 'OriginalFilename'} (PDFy mirror)"
					description: """
						<p>
							<strong>This public document was automatically mirrored from <a href="https://pdf.yt/">PDFy</a>.</strong>
						</p>

						<ul>
							<li><strong>Original filename:</strong> #{task.document.get 'OriginalFilename'}</li>
							<li><strong>URL:</strong> <a href="http://pdf.yt/d/#{task.document.get 'SlugId'}">https://pdf.yt/d/#{task.document.get 'SlugId'}</a></li>
							<li><strong>Upload date:</strong> #{uploadDate.format 'MMMM D, YYYY HH:mm:ss'}</li>
						</ul>
					""".replace("\n", "")

				# TODO: Replace this with a more light-weight extend module such as xtend?
				headers = _({})
					.extend iaHeaders(metadata)
					.extend
						'x-archive-auto-make-bucket': 1
						'x-archive-size-hint': filesize
						'authorization': "LOW #{context.config.ia.access_key}:#{context.config.ia.secret_key}"
					.extend (task.extraHeaders ? {})
					.value()

				#Promise.resolve(headers)
				bhttp.put "http://s3.us.archive.org/#{identifier}/#{encodeURIComponent(task.document.get 'OriginalFilename')}", task.stream, headers: headers
			.then (response) ->
				switch response.statusCode
					when 200 then Promise.resolve()
					when 503 then retryTask task, context
					else Promise.reject new Error "Received a non-200 response from IA (#{response.statusCode})"
	.then ->
		task.document.set "Mirrored", 1
		task.document.saveChanges()
	.catch (err) ->
		task.document
			.set "Mirrored", 2
			.saveChanges()
			.then -> Promise.reject err


module.exports = runTask
