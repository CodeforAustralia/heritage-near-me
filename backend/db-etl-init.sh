#!/usr/bin/env bash

# do this before running `npm start` in etl/

createdb hnm
psql hnm -c 'CREATE EXTENSION postgis;'
psql hnm -f hnm-tables.sql
psql hnm -f hnm-views+functions.sql

