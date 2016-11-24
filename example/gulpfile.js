var gulp = require('gulp');
var elm = require('gulp-elm');
var plumber = require('gulp-plumber');
var del = require('del');
var connect = require('gulp-connect');

var paths = {
  dest: 'dist',
  main: 'ReplicateExample.elm',
  elm_files: './*.elm',
  staticAssets: '*.{html,css}'
};

gulp.task('clean', function(cb) {
  del([paths.dest], cb);
});

gulp.task('elm-init', elm.init);

gulp.task('elm', ['elm-init'], function() {
  return gulp.src(paths.main)
    .pipe(plumber())
    .pipe(elm({filetype: "html"}))
    .pipe(gulp.dest(paths.dest))
    .pipe(connect.reload());
});

gulp.task('static', function() {
  return gulp.src(paths.staticAssets)
    .pipe(plumber())
    .pipe(gulp.dest(paths.dest))
    .pipe(connect.reload());
});

gulp.task('watch', function() {
  gulp.watch(paths.elm_files, ['elm']);
  gulp.watch(paths.staticAssets, ['static']);
});

gulp.task('connect', function() {
  connect.server({
    root: 'dist',
    livereload: true
  });
  
});

gulp.task('build', ['elm', 'static']);
gulp.task('dev', ['build', 'watch', 'connect']);
gulp.task('default', ['build']);
