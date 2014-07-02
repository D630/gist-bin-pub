#!/usr/bin/env bash

# Get a server ip (random) for proxychains

__get()
{
    line_number=$(wc -l < ${HOME}/.proxychains/server_list.txt)
    line_random=$(expr "$RANDOM" % "$line_number")
}

__select() { printf '%s\n' "$(sort -Rr ${HOME}/.proxychains/server_list.txt | head -n"$line_random" | sort -Rr | sed -n -e'#^$#d' -e'$p')" ; }

__main()
{
    if ((line_random > 0))
    then
        __select
    else
        __get
        __main
    fi
}

__get
__main
