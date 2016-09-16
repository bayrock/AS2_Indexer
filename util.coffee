
fs = require 'fs'
songmeta = require 'musicmetadata'
sql = require 'sqlite3'
config = require './config'

#establish local database
library = config.AS2MusicLibrary
db_exists = fs.existsSync library

if not db_exists
	console.log "Path #{library} not found!"
	console.log "Alter this path in config.json"
	return
else
	db = new sql.Database library

#util methods
exports.IndexDirectory = (dir) ->
	fs.readdir dir, (err, list) =>
		if err?
			console.log "Error reading directory: #{dir}"
			return

		for file in list
			path = "#{dir}\\#{file}"
			stat = fs.statSync path

			if stat.isDirectory()
				#dive subdirectories
				@IndexDirectory path
			else
				#cache music
				extension = path.split('.').pop()
				audio =  /^(mp3|flac|wav|m4a)$/i
				@CacheSong path if audio.test extension

		console.log "Finished crawling #{dir}!"

exports.CacheSong = (file) ->
	songdata = fs.createReadStream file
	parser = songmeta songdata, (err, meta) =>
		if err?
			console.log "Error parsing #{file}:\n#{err}"
			return

		@_pushArtistToDB meta

exports._pushSongToDB = (song) ->
	#select artist id and insert the song meta
	#console.log "Cached song #{song.artist} - #{song.title}!"

exports._pushArtistToDB = (song) ->
	empty = ""
	artist = if song.artist[0]? then song.artist[0] else empty
	title = if song.title? then song.title else empty

	if artist is empty
		console.log "Unable to cache artist for song: #{song}"
		return

	db.serialize () =>
		db.each "SELECT name FROM artists WHERE name='#{artist}' LIMIT 1", (err, row) =>
			@_pushSongToDB song if row?
		, (err, rows) =>
			if rows is 0
				query = db.prepare "INSERT INTO artists (name) VALUES (?)"
				query.run(artist)
				query.finalize()
				@_pushSongToDB song
				console.log "Cached artist #{artist}!"
