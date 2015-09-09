$ = require "jquery"
require "Base64"

$ ->
	selectedMethod = undefined
	selectedAmount = undefined
	selectedHasPrice = undefined
	pulsateRemove = undefined

	paypalHandler = (block) ->
		block.find "input.amount"
			.val (Math.round(selectedAmount * 100) / 100)

	paymentMethodHandlers =
		paypal: paypalHandler
		"paypal-weekly": paypalHandler
		"paypal-monthly": paypalHandler
		bitcoin: (block) ->
			block.find(".loading-message").show()
			block.find(".loaded-content").hide()

			$.get "/donate/convert/btc?amount=#{selectedAmount}", (btcAmount) ->
				roundedAmount = Math.round(btcAmount * 100000000) / 100000000
				
				$.get "/donate/bip21?amount=#{roundedAmount}", (uri) ->
					$(".bip21").attr("href", uri)

					block.find(".loading-message").hide()
					block.find(".loaded-content").show()

				$(".bip21-qr").attr("src", "/donate/bip21/qr?amount=#{roundedAmount}")
				$(".btc-amount").text(roundedAmount)

	setCustomValue = (value) ->
		value = parseFloat(value)

		if isNaN value
			# TODO: Validation error!
			value = 0

		selectedAmount = value

	$ "#custom_amount_input"
		.on "keyup", (event) ->
			setCustomValue $(this).val()
			showInstructions()
		.on "change", (event) ->
			setCustomValue $(this).val()
			showInstructions()
		.on "click", (event) ->
			#$ this
			#	.closest ".option"
			#	.find "input[type='radio']"
			#	.click()

			#event.stopPropagation()


	$ "#amount_custom"
		.on "click", (event) ->
			setCustomValue $("#custom_amount_input").val()

	$ ".donation-page section.types .option input[type='radio']"
		.on "click", (event) ->
			# Hide any instructions that were already visible.
			# TODO: Automatically show instructions again when switching back...?
			$ ".donation-page section.instructions div"
				.hide()

			$ ".donation-page section.instructions .placeholder"
				.show()

			type = $ this
				.closest ".option"
				.data "type"

			$ ".donation-page section.methods .option"
				.hide()

			$ ".donation-page section.methods .option[data-type='#{type}']"
				.show()

	$ ".donation-page section.methods .option input[type='radio']"
		.on "click", (event) ->
			optionElement = $ this
				.closest ".option"

			selectedMethod = method = optionElement.data "name"
			selectedHasPrice = setPrice = !!(optionElement.data "set-price")

			if setPrice
				$ ".donation-page section.amount"
					.slideDown(400)

				instructionSection = $ ".donation-page section.instructions"

				instructionSection
					.children "h3.set-amount"
					.show()

				instructionSection
					.children "h3.no-set-amount"
					.hide()
			else
				$ ".donation-page section.amount"
					.slideUp(400)

				instructionSection = $ ".donation-page section.instructions"

				instructionSection
					.children "h3.set-amount"
					.hide()

				instructionSection
					.children "h3.no-set-amount"
					.show()

			showInstructions()

	$ ".donation-page section.amount .option input[type='radio']"
		.on "click", (event) ->
			if not ($(this).attr("id") == "amount_custom")
				selectedAmount = $(this).val()

			showInstructions()

	showInstructions = ->
		$ ".donation-page section.instructions .method"
			.hide()

		if selectedMethod? and (selectedAmount? or !selectedHasPrice)
			$ ".donation-page section.instructions .placeholder"
				.hide()

			$ ".donation-page section.instructions .method-#{selectedMethod}"
				.show()

			#$ "html, body"
			#	.animate scrollTop: "#{$('.donation-page section.instructions').offset().top}px", 500

			$ ".donation-page section.instructions"
				.addClass "pulsate"

			if pulsateRemove?
				clearTimeout pulsateRemove

			pulsateRemove = setTimeout (->
				$ ".donation-page section.instructions"
					.removeClass "pulsate"
			), 3000

			if selectedMethod of paymentMethodHandlers
				paymentMethodHandlers[selectedMethod]($(".donation-page section.instructions .method-#{selectedMethod}"))
		else
			$ ".donation-page section.instructions .placeholder"
				.show()


	$ ".donation-page .option input[type='radio']"
		.on "click", (event) ->
			$ this
				.closest "section"
				.find ".option"
				.removeClass "selected"

			$ this
				.closest ".option"
				.addClass "selected"

			$ this
				.closest ".option"
				.find "input[type='number']"
				.focus()

			event.stopPropagation()

	$ ".donation-page .option"
		.on "click", (event) ->
			$ this
				.find "input[type='radio']"
				.click()

	$ ".donation-page section.types .option[data-type='once']"
		.click()

	$ ".donation-page #amount_10"
		.click()

	$ ".donation-page section.instructions .method, .donation-page section.instructions h3.no-set-amount"
		.hide()

	$ ".js-unavailable"
		.hide()

	$ ".js-available"
		.show()

	$ ".decodable"
		.each ->
			$(this).html atob($(this).html())

