#!/usr/bin/env bash

INIT_SQL=$1

su postgres -c "createdb hnm"
su postgres -c "psql hnm -c 'CREATE EXTENSION postgis;'"
su postgres -c "psql hnm -c 'CREATE EXTENSION IF NOT EXISTS pgcrypto;'"
su postgres -c "psql hnm -c 'CREATE SCHEMA IF NOT EXISTS basic_auth;'"
su postgres -c "psql hnm -f $INIT_SQL"
