$ = require "jquery"

castBoolean = (value) ->
	if value == true
		return 1
	else
		return 0

updateEmbedCode = ->
	showToolbar = $("#show_toolbar").prop("checked")
	showDonationLink = $("#show_donation").prop("checked")

	embedCode = embed_template
		.replace "{SPARSE}", castBoolean(not showToolbar)
		.replace "{DONATION}", castBoolean(showDonationLink)

	$(".embed_code").val embedCode

$ ->
	$ ".autoselect"
		.on "click", (event) ->
			$ this
				.focus()
				.select()

	$ "#show_toolbar, #show_donation"
		.on "change", (event) ->
			updateEmbedCode()

	# Linkify has a tendency of breaking our embed codes, so we re-set the embed code here to make sure that that doesn't happen.
	if embed_template?
		updateEmbedCode()
		# do things and stuff
