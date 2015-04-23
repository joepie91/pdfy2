export NODE_ENV=production
export PORT=80
forever start -l ./logs/forever.reporter.log -o ./logs/stdout.reporter.log -e ./logs/stderr.reporter.log -c coffee ./error-reporter.coffee
authbind --deep forever start -l ./logs/forever.app.log -o ./logs/stdout.app.log -e ./logs/stderr.reporter.log -c coffee ./bin/www
