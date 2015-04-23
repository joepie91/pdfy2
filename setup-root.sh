set -e

useradd pdfy
cd /home/pdfy

apt-get install -y authbind
npm install -g coffee-script forever

touch /etc/authbind/byport/80
chown pdfy /etc/authbind/byport/80
chmod 755 /etc/authbind/byport/80

su -c "./setup.sh" pdfy

echo "Done!"
