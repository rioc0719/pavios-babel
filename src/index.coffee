'use strict'

taskName = 'Babel' # used with humans
safeTaskName = 'babel' # used with machines

babel = require 'gulp-babel'
uglify = require 'gulp-uglify'

{getConfig, gulp, API: {notify, merge, $, reload, handleError, typeCheck, debug}} = require 'pavios'
debug = debug 'task:' + taskName

config = getConfig safeTaskName

defaultOpts =
  minify: no
  sourcemaps: yes
  renameTo: null
  insert: null
  compilerOpts:
    loose: ['es6.forOf']
    modules: 'amd'
    comments: no
    stage: 0

for srcDestPair in config
  srcDestPair.opts = Object.assign {}, defaultOpts, srcDestPair.opts

# debug 'Merged config: ', config

result = typeCheck.standard config, taskName, typeCheck.types.standardOpts
debug 'Type check ' + (if result then 'passed' else 'failed')

gulp.task safeTaskName, (cb) ->
  unless result
    debug 'Exiting task early because config is invalid'
    return cb()

  streams = []

  for {src, dest, opts} in config
    if src.length > 0 and dest.length > 0
      debug "Creating stream for src #{src} and dest #{dest}..."
      streams.push(
        gulp.src src
        .pipe do handleError taskName
        .pipe $.changed(dest, extension: '.js')
        .pipe $.if(opts.sourcemaps is yes, $.sourcemaps.init())
        .pipe $.if(typeCheck.raw(typeCheck.types.insert, opts.insert), $.insert(opts.insert))
        .pipe babel opts.compilerOpts
        .pipe $.if(opts.minify is yes, uglify())
        .pipe $.if(typeCheck.raw(typeCheck.types.renameTo, opts.renameTo), $.rename(opts.renameTo))
        .pipe $.if(opts.sourcemaps is yes, $.sourcemaps.write())
        .pipe gulp.dest dest
        .pipe reload()
        .on 'end', -> notify.taskFinished taskName
      )

  merge streams

module.exports.order = 1
module.exports.sources = (src for {src} in config)
