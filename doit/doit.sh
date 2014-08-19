#!/usr/bin/env bash

# Grep and convert german dates with dateutils (dgrep & strptime)

# doit.sh <FILE>

# DIN 1355-1 => ISO 8601 / DIN 5008
# DIN 5008 mit zwei Leerzeichen und 4-stellige Jahreszahl => ISO 8601 / DIN 5008

while IFS= read -r
do
    if [[ $REPLY =~ [[:digit:]]{2}[[:punct:]][[:space:]][[:alpha:]]{2,3}[[:space:]][[:digit:]]{4} ]]
    then
        printf '%s => %s\n' "$REPLY" "$(strptime -e -i "%d. %b %Y" -f "%Y-%m-%d" "$REPLY")"
    elif [[ $REPLY =~ [[:digit:]]{2}[[:punct:]][[:space:]][[:alpha:]]{4,}[[:space:]][[:digit:]]{4} ]]
    then
        printf '%s => %s\n' "$REPLY" "$(strptime -e -i "%d. %B %Y" -f "%Y-%m-%d" "$REPLY")"
    elif [[ $REPLY =~ [[:digit:]]{2}[[:punct:]][[:digit:]]{2}[[:punct:]][[:digit:]]{2} ]]
    then
        printf '%s ==> %s\n' "$REPLY" "$(strptime -e -i "%d.%m.%Y" -f "%Y-%m-%d" "$REPLY")"
    fi
done < <(dgrep -z CEST --from-zone=CEST -e -o -i '%d.%m.%Y' -i '%d. %b %Y' -i '%d. %B %Y' --gt "1970-01-01" < "$1" )
