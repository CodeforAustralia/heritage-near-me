#!/usr/bin/env bash

INIT_SQL=$1

createdb hnm
psql hnm -c 'CREATE EXTENSION postgis;'
psql hnm -f $INIT_SQL
