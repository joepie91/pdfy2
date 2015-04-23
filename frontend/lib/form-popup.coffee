$ = require "jquery"

$ ->
	$(".popup").hide()

	$(".form-popup").each ->
		elem = $(this)
		target = ".popup-#{elem.data('popup')}"

		elem.on "click", ->
			$(target).show()

		$(".popup .close").on "click", ->
			$(this)
				.closest ".popup"
				.hide()
