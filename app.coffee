
program = require 'commander'
pkg = require './package'
util = require './util'

program
	.version(pkg.version)
	.option('-d, --dir <directory>', 'directory to index')
	.parse(process.argv)

if not program.dir?
	program.outputHelp()
	return

if not /^(.+)\\([^\\]+)$/i.test(program.dir)
	console.log("Invalid directory format!")
	return

util.IndexDirectory(program.dir)
