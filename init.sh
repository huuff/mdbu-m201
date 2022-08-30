#!/usr/bin/env bash

gunzip < /mnt/datafiles/people.json.gz | mongoimport --db m201 --collection people --drop --host localhost --port 27017

gunzip < /mnt/datafiles/restaurants.json.gz | mongoimport --db m201 --collection restaurants --drop --host localhost --port 27017
