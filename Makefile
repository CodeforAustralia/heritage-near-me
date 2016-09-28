
help:
	@echo "run 'make data' to wipe and reload the database"

data:
	dropdb --if-exists hnm
	cd backend && ./db-etl-init.sh
	cd etl && npm start	

DB=hnm
DB_USER=postgres

server-permissions:
	chgrp -R $(DB_USER) /root
	chmod -R g+rx /root

server-dbinit:
	cd backend && su $(DB_USER) -c ./dbinit.sh

server-dropdb:
	su postgres -c "dropdb --if-exists $(DB)"

server-install-api-service:
	sudo touch /var/log/heritage-api.log
	sudo chown postgres /var/log/heritage-api.log
	sudo mkdir -p /var/run/heritage
	sudo chown postgres /var/run/heritage
	sudo cp server/heritage-api.conf /etc/init

server-apistart:
	sudo service heritage-api start

server-update-from-git:
	git pull

server-update-live-files:
	cp -r prototype/* /usr/share/nginx/www

reload-nginx:
	nginx -s reload