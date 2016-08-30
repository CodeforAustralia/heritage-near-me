
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

RUN_API="postgrest postgres://localhost:5432/hnm --port 3000 --schema hnm --anonymous $(DB_USER) --pool 200"

server-apistart:
	screen -S hnm-api -d -m $(RUN_API)

server-update-from-git:
	git pull

server-update-live-files:
	cp -r prototype/* /usr/share/nginx/www

reload-nginx:
	nginx -s reload