Promise = require "bluebird"

module.exports = (task, context) ->
	Promise.try ->
		# SPEC: Upload to Tahoe-LAFS for CDN
	.then (response) ->
		# SPEC: Check for errors
		# SPEC: Retrieve database model
	.then (document) ->
		# SPEC: Update database model
