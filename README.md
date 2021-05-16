# PDFy

This is the source code for [PDFy](https://pdf.yt/).

## Setup

1. Use NVM to switch to Node 0.12
2. ./setup.sh
3. npm install knex@0.7.6 coffee-script@1.7.1 --global
4. knex migrate:latest
5. coffee bin/www.coffee
6. curl -F 'file=@/path/to/a/pdf' -F 'visibility=public' http://localhost:3000/upload
5. ??? (I'm trying, I really am, but this might not be the whole story)
6. PROFIT!

## License

[WTFPL](http://www.wtfpl.net/txt/copying/) or [CC0](https://creativecommons.org/publicdomain/zero/1.0/), whichever you prefer.

Note: lib/connect-busboy/connect-busboy.js is from an external project, and is MIT licensed.