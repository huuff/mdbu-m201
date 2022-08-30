#!/usr/bin/env bash

# TODO: Use username and password from env vars
cat /mnt/datafiles/people.json.gz | gunzip | mongoimport --collection people --drop --host localhost --port 27017
