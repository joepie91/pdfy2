TaskRunner = require "../lib/task-runner"
Promise = require "bluebird"

runner = new TaskRunner()

runner.addTask "testTask", ((task, context) ->
	new Promise (resolve, reject) ->
		setTimeout ( ->
			resolve(task.value * 2)
		), (Math.random() * 10)
), maxConcurrent: 10

for i in [0...10000]
	runner.do "testTask", value: Math.round(Math.random() * 100)
		.then (val) -> console.log "VAL", val

runner.run()
