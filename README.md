# PDFy

This is the source code for [PDFy](https://pdf.yt/).

## Setup

1. Use nvm to install node 17
2. ./setup.sh
3. npx knex migrate:latest
4. npx -p gulp-cli gulp
5. npx coffee bin/www.coffee
6. curl -F 'file=@/path/to/a/pdf' -F 'visibility=public' http://localhost:3000/upload
7. ??? (I'm trying, I really am, but this might not be the whole story)
8. PROFIT!

## License

[WTFPL](http://www.wtfpl.net/txt/copying/) or [CC0](https://creativecommons.org/publicdomain/zero/1.0/), whichever you prefer.