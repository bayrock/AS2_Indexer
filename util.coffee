
fs = require 'fs'
songmeta = require 'musicmetadata'

exports.IndexDirectory = (dir) ->

	fs.readdir dir, (err, list) =>
		if err?
			console.log("Error reading directory!")
			return

		for file in list
			path = "#{dir}\\#{file}"
			stat = fs.statSync(path)

			if stat.isDirectory()
				#dive subdirectories
				@.IndexDirectory(path)
			else
				#cache music
				extension = path.split('.').pop()
				audio =  /^(mp3|flac|wav|m4a)$/i
				@.CacheSong(path) if audio.test extension

		console.log("Finished crawling #{dir}!")

exports.CacheSong = (song) ->
	songdata = fs.createReadStream(song)
	parser = songmeta songdata, (err, meta) ->
		if err?
			console.log("Error parsing #{song}:\n#{err}")
			return

		console.log(meta)
