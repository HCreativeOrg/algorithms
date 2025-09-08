import gulp from "gulp";
import coffee from "gulp-coffee";

gulp.task("coffee", async (done) => {
    await gulp.src('./src/*.coffee')
        .pipe(coffee({bare: true}))
        .pipe(gulp.dest('./dist/'));
    done();
});

gulp.task("default", gulp.series("coffee"));