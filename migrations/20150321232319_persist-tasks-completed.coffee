rfr = require "rfr"
persist = rfr "lib/persist"

migrateTaskType = (name) ->
	Promise.all [
		persist.setItem "task:#{name}:completed", 0
	]

rollbackTaskType = (name) ->
	Promise.all [
		persist.removeItem "task:#{name}:completed"
	]

exports.up = (knex, Promise) ->
	Promise.all [
		migrateTaskType "mirror"
		migrateTaskType "thumbnail"
	]

exports.down = (knex, Promise) ->
	Promise.all [
		rollbackTaskType "mirror"
		rollbackTaskType "thumbnail"
	]
