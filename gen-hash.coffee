#!/usr/bin/env coffee

scrypt = require "scrypt-kdf"
Promise = require "bluebird"
read = Promise.promisify(require "read")

Promise.try ->
	read(prompt: "Enter a password:", silent: true)
.spread (password, isDefault) ->
	if password.trim().length == 0
		console.log "You didn't enter a password!"
		process.exit(1)

	scrypt.kdf(password, {logN: 15})
.then (hash) ->
	console.log "Hash:", hash.toString('base64')
	console.log "Set this hash in your config.json to use it."
