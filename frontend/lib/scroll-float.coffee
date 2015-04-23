$ = require "jquery"

module.exports = (jqueryObj) ->
	jqueryObj.each ->
		elem = $(this)
		minTop = threshold = basePos = undefined
		currentlyFloating = false

		originalPositioning = elem.css "position"
		originalLeft = elem.css "left"
		originalTop = elem.css "top"
		originalLeft = elem.css "right"

		updateMetrics = ->
			needRestore = currentlyFloating

			if needRestore
				makeNotFloating()

			basePos = elem.offset()
			minTop = elem.data("min-top") ? 0
			threshold = basePos.top - minTop

			if needRestore
				makeFloating()

		makeFloating = ->
			currentlyFloating = true
			elem.css
				position: "fixed"
				top: "#{minTop}px"
				right: "auto"
				left: "#{basePos.left}px"

		makeNotFloating = ->
			currentlyFloating = false
			elem.attr "style", ""
			#elem.css
			#	position: originalPositioning
			#	top: originalTop

		updateMetrics()
		$(window).on "resize", updateMetrics

		$(document).on "scroll", (event) ->
			if $(document).scrollTop() >= threshold
				makeFloating()
			else
				makeNotFloating()
