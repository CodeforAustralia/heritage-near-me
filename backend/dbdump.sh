#!/bin/bash

pg_dump --clean --no-own --if-exists -x hnm > structure-and-data.sql

