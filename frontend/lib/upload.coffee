$ = require "jquery"
prettyUnits = require "pretty-units"

# The AMD loader for this package doesn't work for some reason - so we explicitly disable it. This will force it to fall back to the CommonJS API.
require "blueimp-file-upload/js/jquery.fileupload"

data_object = null

uploadDone = (response) ->
	switch response.status
		when 415
			errorHeader = "Oops! That's not a PDF file."
			errorMessage = "The file you tried to upload is not a valid PDF file. Currently, only PDF files are accepted."
		when 413
			errorHeader = "Oops! That file is too big."
			errorMessage = "The file you tried to upload is too big. Currently, you can only upload PDF files up to 150MB in size."
		when 200 # Nothing, success!
		else
			errorHeader = "Oops! Something went wrong."
			errorMessage = "An unknown error occurred. Please reload the page and try again. If the error keeps occurring, <a href='mailto:pdfy@cryto.net'>send us an e-mail</a>!"

	if errorMessage?
		triggerError errorHeader, errorMessage
		reinitializeUploader()
	else
		if response.responseJSON.redirect?
			window.location = response.responseJSON.redirect
		else
			# TODO: Wat do?

triggerError = (header, message) ->
	$(".upload-form .privacySettings, .upload-form .progress, .upload-form .button-submit").hide()
	$(".upload").removeClass("faded")

	errorBox = $("#uploadError")
		.show()

	errorBox.find "h3"
		.html header

	errorBox.find ".message"
		.html message

	data_object = null

reinitializeUploader = ->
	$("#upload_element").replaceWith($("#upload_element").clone(true))

filePicked = (data) ->
	$(".upload-form .privacySettings, .upload-form .button-submit").show()
	$("#uploadError").hide()
	$(".upload-form .fileinfo").removeClass("faded")

	fileinfo = $(".fileinfo")
	filesize = data.files[0].size

	# TODO: Use filesize limit from configuration file!
	if filesize > (150 * 1024 * 1024)
		reinitializeUploader()
		triggerError("Oops! That file is too big.", "The file you tried to upload is too big. Currently, you can only upload PDF files up to 150MB in size.")
		return

	filesize_text = prettyUnits(filesize) + "B"

	fileinfo.find ".filename"
		.text data.files[0].name

	fileinfo.find ".filesize"
		.text filesize_text

	$ ".info"
		.hide()

	fileinfo
		.show()

	$ ".upload"
		.addClass "faded"

updateUploadProgress = (event) ->
	if event.lengthComputable
		percentage = event.loaded / event.total * 100

		done_text = prettyUnits(event.loaded) + "B"
		total_text = prettyUnits(event.total) + "B"

		progress = $ ".progress"

		progress.find ".done"
			.text done_text

		progress.find ".total"
			.text total_text

		progress.find ".percentage"
			.text (Math.ceil(percentage * 100) / 100)

		progress.find ".bar-inner"
			.css width: "#{percentage}%"

		if event.loaded >= event.total
			# Completed!
			progress.find ".numbers"
				.hide()

			progress.find ".wait"
				.show()

$ ->
	if $().fileupload?
		# Only run this if the fileupload plugin is loaded; we don't need all this on eg. the 'view' page.

		$ "#upload_form"
			.fileupload
				fileInput: null
				type: "POST"
				url: "/upload"
				paramName: "file"
				autoUpload: false
				maxNumberOfFiles: 1
				formData: (form) ->
					form = $ "#upload_form"
					form.serializeArray()
				progressall: (e, data) ->
					updateUploadProgress
						lengthComputable: true
						loaded: data.loaded
						total: data.total
				add: (e, data) ->
					data_object = data
					filePicked(data)
				always: (e, data) ->
					uploadDone(data.jqXHR)

	$ "#upload_activator"
		.on "click", (event) ->
			$("#upload_element").click()

	$ "#upload_element"
		.on "change", (event) ->
			filePicked(this)

	$ "#upload_form"
		.on "submit", (event) ->
			event.stopPropagation()
			event.preventDefault()

			$ ".fileinfo"
				.addClass "faded"

			$ ".progress"
				.show()

			if data_object == null
				# Only do this if the drag-and-drop dropzone hasn't been used.
				formData = new FormData(this)

				$.ajax
					method: "POST"
					url: "/upload"
					data: formData
					cache: false
					contentType: false
					processData: false
					xhr: ->
						customHandler = $.ajaxSettings.xhr()

						if customHandler.upload?
							customHandler.upload.addEventListener "progress", updateUploadProgress, false

						return customHandler
					complete: (result) ->
						uploadDone(result)
			else
				# If the dropzone was used...
				data_object.submit()
