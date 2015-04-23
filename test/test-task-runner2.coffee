TaskRunner = require "../lib/task-runner"
Promise = require "bluebird"
bhttp = require "bhttp"

testTaskFunc = (task, context) ->
	Promise.try ->
		bhttp.get "http://somesite.com/user/#{task.id}", decodeJSON: true
	.then (response) ->
		context.db.hypotheticalInsert("users", {id: task.id, name: response.body.name})

runner = new TaskRunner(db: hypotheticalDatabaseConnection)

runner.addTask "testTask", testTaskFunc, maxConcurrent: 10

for i in [0...10000]
	runner.do "testTask", id: i
		.then (model) -> console.log "Done user", i

runner.run()
