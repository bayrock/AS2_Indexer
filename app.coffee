
program = require 'commander'
pkg = require './package'
util = require './util'

program
	.version pkg.version
	.option '-d, --dir <directory>', 'directory to index'
	.parse process.argv

if not program.dir?
	program.outputHelp()
	return

if not /^(.+)\\([^\\]+)$/.test(program.dir)
	console.log "Invalid directory format!"
	return

util.IndexDirectory program.dir

process.on 'exit', (exitCode) ->
	if not exitCode is 0
		console.log "Fatal error occured caching songs!\nExiting.."
		return
	util._finalizeSongQueries(program.dir)
