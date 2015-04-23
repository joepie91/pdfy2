rfr = require "rfr"
persist = rfr "lib/persist"

initializeVariable = (name, type, initialValue) ->
	Promise.all [
		persist.addListItem "variableTypes",
			name: name
			type: type

		persist.setItem "var:#{name}", initialValue
	]

removeVariable = (name) ->
	Promise.all [
		persist.removeListItemByFilter "variableTypes", (item) ->
			return (item.name == name)

		persist.removeItem "var:#{name}"
	]

exports.up = (knex, Promise) ->
	Promise.all [
		initializeVariable "donationGoal", "number", 500
		initializeVariable "donationTotal", "number", 0
		initializeVariable "showNotice", "boolean", false
	]

exports.down = (knex, Promise) ->
	Promise.all [
		removeVariable "donationGoal"
		removeVariable "donationTotal"
		removeVariable "showNotice"
	]
