#!/usr/bin/env bash

# obrc - build openbox configuration file (poor man's method)

case $1 in
    -c|--cat)
        command cat \
            <(builtin printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<openbox_config xmlns="http://openbox.org/3.5/rc">') \
            "${XDG_CONFIG_HOME}"/openbox/rc-*.xml \
            <(builtin printf '%s\n' '</openbox_config>') \
            > "${XDG_CONFIG_HOME}/openbox/rc.xml"
        ;;
    -s|--split)
        builtin declare i=
        builtin declare -a "sections=(
            applications
            desktops
            dock
            focus
            keyboard
            margins
            menu
            mouse
            placement
            resistance
            resize
            theme)"
        for i in "${sections[@]}"
        do
            command sed -n "/<${i}> <!-- ${i^^} -->/,/<\/${i}>/ p" "${XDG_CONFIG_HOME}/openbox/rc.xml" \
                > "${XDG_CONFIG_HOME}/openbox/rc-${i}.xml"
        done
        ;;
    *)
        { echo "Usage: obrc (-c|--cat|-s|--split)" 1>&2 ; exit 1 ; }
esac
