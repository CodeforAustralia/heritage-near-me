#!/usr/bin/env bash

INIT_SQL=$1

su postgres -c "createdb hnm"
su postgres -c "psql hnm -f $INIT_SQL"
