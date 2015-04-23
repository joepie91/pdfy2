require "./lib/upload"
require "./lib/embed"
require "./lib/donate"
require "./lib/form-popup"

$ = require "jquery"
autosize = require "autosize"
marked = require "marked"
scrollFloat = require "./lib/scroll-float"

$ ->
	$(".checkAll").on "change", (event) ->
		newValue = $(this).prop("checked")

		$(this)
			.closest "table"
			.find "input[type='checkbox']"
			.filter ->
				return !$(this).hasClass "checkAll"
			.prop "checked", newValue

	scrollFloat($(".floating"))

	autosize($(".md-editor"))

	updatePreview = ->
		$(".md-preview").html(marked($(this).val()))

	$(".md-editor")
		.on "change input propertychange", updatePreview
		.each updatePreview




