#!/usr/bin/env bash

createdb hnm
psql hnm -f structure-and-data.sql

