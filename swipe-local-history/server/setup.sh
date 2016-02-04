#!/usr/bin/env bash

FRONTEND="swipe-local-history/prototype" 
BACKEND="swipe-local-history/backend" 
SERVER="swipe-local-history/server" 

DB_DATA="/usr/local/pgsql/data"

sudo apt-get install nginx -y
sudo apt-get install git -y
sudo apt-get install postgresql postgresql-contrib -y
sudo apt-get install daemon -y

cd heritage-near-me
git remote add -f origin https://github.com/kennib/heritage-near-me.git
git config core.sparseCheckout true
echo $FRONTEND >> .git/info/sparse-checkout
echo $BACKEND >> .git/info/sparse-checkout
echo $SERVER >> .git/info/sparse-checkout
git pull origin master

groupadd postgres
gpasswd -a postgres postgres
chgrp -R postgres /root
chmod -R g+rwx /root

git init heritage-near-me

cp -r $FRONTEND /usr/share/nginx/www

./$BACKEND/dbinit.sh $BACKEND/heritage-near-me.sql
daemon --name="hnm-api" --output=api.log bash $BACKEND/apistart

cp $SERVER/heritage-near-me /etc/nginx/sites-enabled/heritage-near-me
mv /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
nginx -s reload
