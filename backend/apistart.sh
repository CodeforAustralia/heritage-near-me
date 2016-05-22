#!/usr/bin/env bash
postgrest postgres://localhost:5432/hnm --port 3000 --schema hnm --anonymous `whoami` --pool 200
