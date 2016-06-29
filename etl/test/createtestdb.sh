#!/bin/bash

# create database if it doesn't already exist
# http://stackoverflow.com/a/36591842/1024811
psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'testdb'" | grep -q 1 || psql -U postgres -c "CREATE DATABASE testdb"
