
help:
	@echo "run 'make data' to wipe and reload the database"

data:
	dropdb --if-exists hnm
	cd backend && ./db-etl-init.sh
	cd etl && npm start	
	
