EventEmitter = require("events").EventEmitter
Promise = require "bluebird"
debug = require("debug")("task-runner")

makeExternalPromise = ->
	extResolve = extReject = null
	new Promise (resolve, reject) ->
		extResolve = resolve
		extReject = reject

module.exports = class TaskRunner extends EventEmitter
	constructor: (@context = {}) ->
		@_taskTypes = {}
		@_queue = {}
		@_runningCount = {}
		@running = false
		@context.taskRunner = this

	_checkRunTask: ->
		if not @running
			return

		debug "checking for runnable tasks..."

		for taskType, options of @_taskTypes
			if @_runningCount[taskType] < (options.maxConcurrent ? Infinity)
				if options.maxConcurrent?
					tasksToRun = options.maxConcurrent - @_runningCount[taskType]
				else
					tasksToRun = Infinity

				debug "running #{tasksToRun} tasks"

				for i in [0...tasksToRun]
					if @_queue[taskType].length == 0
						debug "ran out of tasks"
						@emit "tasksDepleted"
						break

					@_doRunTask taskType, @_queue[taskType].shift()

				debug "started #{tasksToRun} tasks, waiting for completion..."

	_doRunTask: (taskType, taskData) ->
		taskOptions = @_taskTypes[taskType]
		@_runningCount[taskType] += 1
		@emit "taskStarted", taskType, taskData.task

		Promise.resolve(taskOptions.taskFunc(taskData.task, @context))
			.then (value) =>
				@_markTaskCompleted taskType, taskData
				taskData.resolveFunc(value)
			.catch (err) =>
				@emit "taskFailed", taskType, taskData.task, err
				taskData.rejectFunc(err)

		debug "started task"

	_markTaskCompleted: (taskType, task) ->
		@_runningCount[taskType] -= 1
		@emit "taskCompleted", taskType, task.task
		debug "completed task"
		@_checkRunTask()

	addTask: (taskType, taskFunc, options = {}) =>
		options.taskFunc = taskFunc
		@_taskTypes[taskType] = options
		@_queue[taskType] = []
		@_runningCount[taskType] = 0
		debug "added task"

	setTaskOptions: (taskType, options) =>
		options.taskFunc = @_taskTypes[taskType].taskFunc
		@_taskTypes[taskType] = options

	do: (taskType, task) =>
		@emit "taskQueued", taskType, task
		debug "queued task"

		new Promise (resolve, reject) =>
			@_queue[taskType].push
				resolveFunc: resolve
				rejectFunc: reject
				task: task

			@_checkRunTask()

	run: =>
		@running = true
		debug "started task loop"
		@_checkRunTask()

	pause: =>
		@running = false
		debug "paused task loop"
