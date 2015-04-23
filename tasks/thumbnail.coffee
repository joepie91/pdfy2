Promise = require "bluebird"
gm = require "gm"
path = require "path"

module.exports = (task, context) ->
	Promise.try ->
		context.db.model("Document").getOneWhere SlugId: task.id
	.then (document) ->
		Promise.try ->
			documentPath = path.join(context.config.storage_path, document.get('Filename'))
			sourceImage = Promise.promisifyAll gm("#{documentPath}[0]")

			thumbnailWidth = context.config.thumbnails.width
			thumbnailHeight = context.config.thumbnails.height

			sourceImage
				.resize thumbnailWidth, thumbnailHeight, "^"
				.crop thumbnailWidth, thumbnailHeight
				.writeAsync path.join(context.thumbnailPath, "#{task.id}.png")
		.then ->
			document.set "Thumbnailed", 1
			document.saveChanges()
