#!/usr/bin/env bash

# Refresh Firefox Profiles

shopt -s extglob
declare tmp_dir=$(mktemp -d --tmpdir)

for i in ${HOME}/.mozilla/firefox/*.!(clean-template|ini)
do
    rsync -var --delete "${tmp_dir}/" "${i}/"
    rsync -var ${HOME}/.mozilla/firefox/*.clean-template/ "${i}/"
done

shopt -u extglob
