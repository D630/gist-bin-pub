#!/usr/bin/env bash

# Get infos from http://www.gaisma.com/

echo
curl -s http://www.gaisma.com/en/location/"${1:-$X_MY_LOCATION1}".html | scrape -be 'table.sun-data' | w3m -dump -T text/html | head
