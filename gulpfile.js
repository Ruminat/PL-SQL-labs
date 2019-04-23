const gulp  = require('gulp');
const pug   = require('gulp-pug');

// gulp.task('blocks', () => {
//   return gulp.src('views/*.pug')
//          .pipe(pug({}))
//          .pipe(gulp.dest('blocks/'))
// });

// gulp.task('synopsis', () => {
//   return gulp.src('synopsis/*.pug')
//          .pipe(pug({}))
// });

// gulp.task('watch-blocks', () => {
//   gulp.watch('views/*.pug', ['blocks'])
// });

// gulp.task('watch-synopsis', () => {
//   gulp.watch('synopsis/*.pug', ['synopsis'])
// });

// gulp.task('default', ['blocks', 'synopsis', 'watch-blocks', 'watch-synopsis']);

function views() {
  return gulp.src(['views/*.pug', 'extras/*.pug', 'synopsis/*.pug', '!**/_*.pug'])
         .pipe(pug())
         .pipe(gulp.dest('html/'));
}

function index() {
  return gulp.src(['index.pug'])
         .pipe(pug())
         .pipe(gulp.dest('./'));
}

function watch() {
  return gulp.watch(['**/*.pug', '**/*.sql'], {delay: 100}, gulp.parallel(views, index));
}

exports.default = gulp.parallel(views, index, watch);