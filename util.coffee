
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

		meta.path = file
		@_pushArtistToDB meta
		#TODO: try adding a timer to prevent collisions

exports._pushSongToDB = (song) ->
	db.serialize () =>
		artist = song.artist[0]

		db.each "SELECT artistid FROM artists WHERE name='#{artist}' LIMIT 1", (err, row) =>
			errorstring = (e) -> "Error: #{e}\nskipping song #{artist} - #{song.title}"
			if err or not row?
				console.log errorstring(err)
				return

			query = db.prepare "INSERT INTO songs (duration, path, name, artistid, searchname, filemodifiedtime) VALUES (?,?,?,?,?, ?)"

			try
				duration = Math.floor song.duration
				path = song.path
				name = song.title
				artistid = row.artistid
				searchname = @_constructSearchName name, artist
				filemodified = Math.floor(new Date() / 1000) #unix epoch
			catch err
				console.log errorstring(err) if err?

			query.run(duration, path, name, artistid, searchname, filemodified)
			query.finalize()
			console.log "Cached song #{song.artist} - #{song.title}!"

exports._pushArtistToDB = (song) ->
	empty = ""
	artist = if song.artist[0]? then song.artist[0] else empty

	errorstring = "Unable to cache artist for song: #{artist} - #{song.title}"
	if artist is empty
		console.log errorstring
		return

	db.serialize () =>
		db.each "SELECT name FROM artists WHERE name='#{artist}' LIMIT 1", (err, row) =>
			console.log errorstring if err?
			@_pushSongToDB song if row?
		, (err, rows) =>
			if rows is 0
				query = db.prepare "INSERT INTO artists (name) VALUES (?)"
				query.run(artist)
				query.finalize()
				@_pushSongToDB song
				console.log "Cached artist #{artist}!"

exports._constructSearchName = (name, artist) ->
	stripped_name = name.replace(/\s/g, '').toLowerCase()
	stripped_artist = artist.replace(/\s/g, '').toLowerCase()
	return "#{stripped_name}.#{stripped_artist}"
