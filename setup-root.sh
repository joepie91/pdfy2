set -e

cd /home/pdfy/pdfy2

apt-get install -y authbind graphicsmagick
npm install -g coffee-script forever

touch /etc/authbind/byport/80
chown pdfy /etc/authbind/byport/80
chmod 755 /etc/authbind/byport/80

chown -R pdfy:pdfy .

su -c "./setup.sh" pdfy

echo "Done!"
