chokidar = require "chokidar"
nodemailer = require "nodemailer"
path = require "path"
fs = require "fs"

watcher = chokidar.watch "./errors", depth: 0, ignoreInitial: true
mailer = nodemailer.createTransport()

processFile = (filePath) ->
	fs.readFile filePath, (err, data) ->
		try
			parsedData = JSON.parse(data)
		catch error
			console.log "Error report not complete yet, retrying #{filePath} in 1 second..."
			setTimeout (->
				processFile(filePath)
			), 1000
			return

		errorMessage = parsedData?.message ? "UNKNOWN ERROR"
		textStack = parsedData?.stack?.replace(/\u001b(?:\[\??(?:\d\;*)*[A-HJKSTfminsulh])?/g, "") ? ""

		message = """
			A failure occurred. #{filePath} is attached.

			#{textStack}
		"""

		htmlMessage = """
			A failure occurred. #{filePath} is attached.

			<pre>#{textStack}</pre>
		""".replace(/\n/g, "<br>")

		mailer.sendMail
			from: "ops@pdf.yt"
			to: "admin@cryto.net"
			subject: "Automatic failure report: #{errorMessage}"
			text: message
			html: htmlMessage
			attachments: [
				filename: path.basename(filePath)
				path: filePath
				contentType: "application/json"
			]

watcher.on "add", (filePath) ->
	console.log "PANIC! Sending report:", filePath
	processFile(filePath)

console.log "Running..."
