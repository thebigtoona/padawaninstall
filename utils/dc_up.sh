#!/bin/bash

echo $(cd "$1" && docker-compose up -d)
