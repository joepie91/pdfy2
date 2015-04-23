var gulp = require('gulp');

/* CoffeeScript compile deps */
var path = require('path');
var gutil = require('gulp-util');
var concat = require('gulp-concat');
var rename = require('gulp-rename');
var coffee = require('gulp-coffee');
var cache = require('gulp-cached');
var remember = require('gulp-remember');
var plumber = require('gulp-plumber');
var livereload = require('gulp-livereload');
var nodemon = require("gulp-nodemon");
var net = require("net");
var webpack = require("gulp-webpack");
var sass = require("gulp-sass");

task = {
	"source": ["public/**/*.coffee", "routes/**/*.coffee", "models/**/*.coffee", "tasks/**/*.coffee", "app.coffee", "util.coffee", "migrate.coffee", "db.coffee"]
}

/*
gulp.task('coffee', function() {
	return gulp.src(task.source, {base: "."})
		.pipe(plumber())
		.pipe(cache("coffee"))
		.pipe(coffee({bare: true}).on('error', gutil.log)).on('data', gutil.log)
		.pipe(remember("coffee"))
		.pipe(gulp.dest("."));
});*/

gulp.task('webpack', function(){
	return gulp.src("frontend/index.coffee")
		.pipe(webpack({
			watch: true,
			module: {
				loaders: [{ test: /\.coffee$/, loader: "coffee-loader" }]
			},
			resolve: { extensions: ["", ".web.coffee", ".web.js", ".coffee", ".js"] }
		}))
		.pipe(rename("bundle.js"))
		.pipe(gulp.dest("public/js/"));
});

gulp.task('sass', function(){
	// TODO: Put the source SCSS file in a more logical place...
	return gulp.src("./public/css/*.scss")
		.pipe(sass())
		.pipe(gulp.dest("./public/css"));
});

function checkServerUp(){
	setTimeout(function(){
		var sock = new net.Socket();
		sock.setTimeout(50);
		sock.on("connect", function(){
			console.log("Trigger page reload...");
			livereload.changed();
			sock.destroy();
		})
		.on("timeout", checkServerUp)
		.on("error", checkServerUp)
		.connect(3000);
	}, 70);
}

gulp.task('watch', function () {
	livereload.listen();
	gulp.watch(['./**/*.css', 'views/**/*.jade', 'package.json', "./public/js/**/*.js"]).on('change', livereload.changed);
	gulp.watch(["./public/css/style.scss"], ["sass"])
	//gulp.watch(task.source, ['coffee']);
	// theseus disabled for now, it was screwing with my tracebacks
	//nodemon({script: "./bin/www", ext: "js", nodeArgs: ['/usr/bin/node-theseus']}).on("start", checkServerUp);
	nodemon({
		script: "./bin/www.coffee",
		ext: "coffee",
		delay: 500,
		ignore: ["./frontend/"],
		watch: ["app.coffee", "bin", "lib", "models", "routes", "tasks"]
	}).on("start", checkServerUp).on("restart", function(file){
		console.log("Restarted triggered by:", file);
	});
});

gulp.task('default', [/*'coffee',*/ 'sass', 'watch', 'webpack']);
