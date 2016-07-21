#!/usr/bin/env bash

createdb hnm
# psql hnm -c 'CREATE EXTENSION postgis;'
# psql hnm -f heritage-near-me.sql
psql hnm -f structure-and-data.sql

