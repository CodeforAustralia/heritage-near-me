#!/usr/bin/env bash

FRONTEND="swipe-local-history/prototype" 
BACKEND="swipe-local-history/backend" 
SERVER="swipe-local-history/server" 

# PostGIS sources
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt trusty-pgdg main" >> /etc/apt/sources.list'
wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

sudo apt-get install nginx -y
sudo apt-get install git -y
sudo apt-get install postgresql postgresql-contrib -y
sudo apt-get install postgresql-9.4-postgis-2.1 postgresql-contrib-9.4 -y
sudo apt-get install daemon -y

cd heritage-near-me
git remote add -f origin https://github.com/CodeforAustralia/heritage-near-me.git
git config core.sparseCheckout true
echo $FRONTEND >> .git/info/sparse-checkout
echo $BACKEND >> .git/info/sparse-checkout
echo $SERVER >> .git/info/sparse-checkout
git pull origin master

groupadd postgres
gpasswd -a postgres postgres
chgrp -R postgres /root
chmod -R g+rx /root

git init heritage-near-me

cp -r $FRONTEND/* /usr/share/nginx/www

./$BACKEND/dbinit.sh $BACKEND/heritage-near-me.sql
screen -S hnm-api -d -m ./$BACKEND/apistart.sh

cp $SERVER/heritage-near-me /etc/nginx/sites-enabled/heritage-near-me
mv /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
nginx -s reload

chgrp -R root /root
