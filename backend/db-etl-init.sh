#!/usr/bin/env bash

# do this before running `npm start` in etl/

createdb hnm
psql hnm -c 'CREATE EXTENSION postgis;'
psql hnm -f heritage-near-me.sql

