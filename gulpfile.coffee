argv     = require('yargs').argv
gulp     = require 'gulp'
gulpif   = require 'gulp-if'
template = require 'gulp-template'


project =
  dest:   './build/'
  src:    './app/**/*.coffee'
  static: './static/**'
  index:  './static/index.html'
  style:  './style/index.less'
  test:   './test/**/*_spec.coffee'


require('vistar-gulp-tasks')(project)



apiRoot = if 'apiRoot' of argv
  argv['apiRoot']
else
  'http://localhost.vistarmedia.com:5555'


gulp.task 'static', ->
  isIndex = (file) -> file.path.indexOf('index.html') isnt -1

  gulp.src(project.static)
    .pipe(gulpif(isIndex, template(apiRoot: apiRoot)))
    .pipe(gulp.dest(project.dest))
