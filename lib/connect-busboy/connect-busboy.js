// From connect-busboy project: < https://www.npmjs.com/package/connect-busboy >

// Copyright Brian White. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and / or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

var Busboy = require('busboy');

var RE_MIME = /^(?:multipart\/.+)|(?:application\/x-www-form-urlencoded)$/i;

module.exports = function (options) {
    options = options || {};

    return function (req, res, next) {
        if (req.busboy
            || req.method === 'GET'
            || req.method === 'HEAD'
            || !hasBody(req)
            || !RE_MIME.test(mime(req)))
            return next();

        var cfg = {};
        for (var prop in options)
            cfg[prop] = options[prop];
        cfg.headers = req.headers;

        req.busboy = new Busboy(cfg);

        if (options.immediate) {
            process.nextTick(function () {
                req.pipe(req.busboy);
            });
        }

        next();
    };
};

// utility functions copied from Connect

function hasBody(req) {
    var encoding = 'transfer-encoding' in req.headers,
        length = 'content-length' in req.headers
            && req.headers['content-length'] !== '0';
    return encoding || length;
};

function mime(req) {
    var str = req.headers['content-type'] || '';
    return str.split(';')[0];
};