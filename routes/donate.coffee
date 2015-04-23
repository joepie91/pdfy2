Promise = require "bluebird"
router = require("express-promise-router")()
moment = require "moment"
bip21 = require "bip21"
qrImage = require "qr-image"

rfr = require "rfr"
getRates = rfr "lib/get-rates"
parseAmount = rfr "lib/parse-amount"

getBip21 = (address, amount) ->
	bip21.encode(address, amount: amount, label: "PDFy donation")

router.get "/", (req, res) ->
	Promise.try ->
		getRates()
	.then (rates) ->
		res.render "donate",
			rates: rates
			currentMonth: moment().format "MMMM YYYY"

router.get "/convert/:currency", (req, res) ->
	Promise.try ->
		getRates()
	.then (rates) ->
		# Floats for money are evil and all that, but we only need approximate numbers here, so it's all fine here. Don't do this where precision is required, though!
		if req.query.amount? and req.params.currency.toUpperCase() of rates
			res.send (rates[req.params.currency.toUpperCase()] * parseFloat(req.query.amount)).toString()
		else
			req.reportError(new Error("Unknown currency specified: #{req.params.currency}"), "warning")
			Promise.reject new Http422Error "No such currency exists."

router.get "/bip21", (req, res) ->
	Promise.try ->
		res.send getBip21(req.appConfig.donations.bitcoinAddress, parseAmount(req.query.amount))

router.get "/bip21/qr", (req, res) ->
	qrImage.image(getBip21(req.appConfig.donations.bitcoinAddress, parseAmount(req.query.amount)), type: "png", size: 3, margin: 1)
		.pipe res

router.get "/faq", (req, res) ->
	res.render "donation-faq"

router.get "/thanks", (req, res) ->
	res.render "donate-thanks"

module.exports = router
