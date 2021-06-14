const { src, dest, series } = require('gulp');
const sass = require('gulp-sass');
const webpackStream = require('webpack-stream');
const rename = require("gulp-rename");
const path = require('path');
const GulpClient = require('gulp');
var coffee = require('gulp-coffee');

sass.compiler = require('node-sass');

var coffeeTask = () =>
    src('frontend/**.coffee')
        .pipe(coffee({ bare: true }))
        .pipe(dest('frontend/'));

var webpackTask = () =>
    src('./frontend/index.js')
        .pipe(webpackStream({
            output: {
                filename: 'bundle.js'
            }
        }))
        .pipe(dest("public/js/"));

var sassTask = () =>
    src('./public/css/*.scss')
        .pipe(sass())
        .pipe(dest("public/css"));

exports.default = series(sassTask, coffeeTask, webpackTask);