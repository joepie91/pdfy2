Promise = require "bluebird"
persist = require "node-persist"
path = require "path"
xtend = require "xtend"

# We MUST explicitly specify the `persist` directory, otherwise node-persist will bug out and write to its own module directory...
persist.initSync(continuous: false, dir: path.join(__dirname, "../persist"))

persist.increment = (key, amount = 1) ->
	persist.setItem key, (persist.getItem(key) + amount)

persist.decrement = (key, amount = 1) ->
	persist.setItem key, (persist.getItem(key) - amount)

persist.addListItem = (key, item) ->
	newList = [item].concat (persist.getItem(key) ? [])

	persist.setItem key, newList

persist.removeListItem = (key, item) ->
	newList = (persist.getItem(key) ? [])
		.filter (existingItem) ->
			return (item == existingItem)

	persist.setItem key, newList

persist.removeListItemByFilter = (key, filter) ->
	newList = (persist.getItem(key) ? [])
		.filter (item) ->
			return !filter(item)

	persist.setItem key, newList

persist.setProperty = (key, propertyKey, value) ->
	newObj = {}
	newObj[propertyKey] = value
	oldObj = persist.get(key)

	persist.setItem key, xtend(oldObj, newObj)

persist.removeProperty = (key, propertyKey) ->
	# Extremely ghetto shallow clone
	obj = xtend({}, persist.get(key))
	delete obj[propertyKey]

	persist.setItem key, obj

# Rough shim for write queueing...
writeQueue = []
currentlyWriting = false
_setItem = persist.setItem

persist.setItem = (key, value) ->
	new Promise (resolve, reject) ->
		_setItem.call(persist, key, value)
		addItemToQueue key, value, resolve, reject
		triggerWrite()

addItemToQueue = (key, value, resolveFunc, rejectFunc) ->
	writeQueue.push [key, value, resolveFunc, rejectFunc]

triggerWrite = ->
	if not currentlyWriting and writeQueue.length > 0
		currentlyWriting = 1
		[key, value, resolveFunc, rejectFunc] = writeQueue.shift()

		Promise.resolve(persist.persistKey(key))
			.then (result) -> resolveFunc(result)
			.catch (err) -> rejectFunc(err)
			.finally ->
				currentlyWriting = false
				triggerWrite()

module.exports = persist
