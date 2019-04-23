const gulp  = require('gulp');
const pug   = require('gulp-pug');
const sass  = require('gulp-sass');

function views () {
  return gulp.src(['views/*.pug', 'extras/*.pug', 'synopsis/*.pug', '!**/_*.pug'])
         .pipe(pug())
         .pipe(gulp.dest('html/'));
}

function index () {
  return gulp.src(['index.pug'])
         .pipe(pug())
         .pipe(gulp.dest('./'));
}

function styles () {
  return gulp.src(['sass/*.sass', '!**/_*.sass', '!**/_*.scss'])
         .pipe(sass())
         .pipe(gulp.dest('css/'));
}

function watchViews () {
  return gulp.watch(['**/*.pug', '**/*.sql'], {delay: 100}, gulp.parallel(views, index));
}

function watchStyles () {
  return gulp.watch(['**/*.sass', '**/*.scss'], {delay: 100}, styles);
}

exports.default = gulp.parallel(views, index, styles, watchViews, watchStyles);