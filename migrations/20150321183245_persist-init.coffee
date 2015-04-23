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

initializeTaskType = (name) ->
	Promise.all [
		persist.addListItem "taskTypes", name
		persist.setItem "task:#{name}:running", 0
		persist.setItem "task:#{name}:queued", 0
		persist.setItem "task:#{name}:failed", 0
	]

removeTaskType = (name) ->
	Promise.all [
		persist.removeListItem "taskTypes", name
		persist.removeItem "task:#{name}:running"
		persist.removeItem "task:#{name}:queued"
		persist.removeItem "task:#{name}:failed"
	]

exports.up = (knex, Promise) ->
	Promise.all [
		initializeVariable "cdnRateLimit", "number", 0
		initializeVariable "announcementText", "string", ""
		initializeVariable "announcementLinkText", "string", ""
		initializeVariable "announcementLink", "string", ""
		initializeVariable "announcementVisible", "boolean", false
		initializeVariable "maintenanceMode", "boolean", false
		initializeVariable "maintenanceModeText", "text", ""
		initializeTaskType "mirror"
		initializeTaskType "thumbnail"
	]

exports.down = (knex, Promise) ->
	Promise.all [
		removeVariable "cdnRateLimit"
		removeVariable "announcementText"
		removeVariable "announcementLinkText"
		removeVariable "announcementLink"
		removeVariable "announcementVisible"
		removeVariable "maintenanceMode"
		removeVariable "maintenanceModeText"
		removeTaskType "mirror"
		removeTaskType "thumbnail"
	]
