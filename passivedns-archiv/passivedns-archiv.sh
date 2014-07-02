#!/usr/bin/env bash

# gzip logs of passivedns

if [[ ! -e /var/log/passivedns-archive/ ]]
then
    sudo mkdir -p /var/log/passivedns-archive/
fi

if [[ -s /var/log/passivedns.log ]]
then
    sudo mv /var/log/passivedns.log /var/log/passivedns-archive/
    sudo gzip -S ".$(date +%Y-%m-%d_%H:%M:%S).gz" /var/log/passivedns-archive/passivedns.log
fi

