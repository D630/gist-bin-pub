#!/usr/bin/env bash

# blscd
# Copyright 2014 D630, GNU GPLv3
# https://github.com/D630/blscd

# Fork and rewrite in GNU bash of lscd v0.1 [GNU GPLv3] by hut aka. Roman
# Zimbelmann, https://github.com/hut/lscd

# -- LICENCE.

# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.

# You should have received a copy of the GNU General
# Public License along with this program. If not, see
# <http://www.gnu.org/licenses/gpl-3.0.html>.

# -- DEBUGGING.

#printf '%s (%s)\n' "$BASH_VERSION" "${BASH_VERSINFO[5]}" && exit 0
#set -o xtrace #; exec 2>> ~/blscd.log
#set -o verbose
#set -o noexec
#set -o errexit
#set -o nounset
#set -o pipefail
#trap '(read -p "[$BASH_SOURCE:$LINENO] $BASH_COMMAND?")' DEBUG

# -- SETTINGS.

#declare vars_base=$(set -o posix ; set)

# -- FUNCTIONS.

__blscd_build_array()
{
    builtin declare i=

    for i
    do
        case $i in
            1)
                if [[ $_blscd_dir_col_1_string == / ]]
                then
                    _blscd_files_col_1_array=(\~)
                    _blscd_files_col_1_array_cursor_index=0
                else
                    builtin mapfile -t _blscd_files_col_1_array \
                        < <(builtin printf '%s\n' "${_blscd_data[path $dir_col_0_string]//|/}")
                fi
                _blscd_files_col_1_array_total=${#_blscd_files_col_1_array[@]}
                ;;
            2)
                [[ ! ${_blscd_data[path ${_blscd_dir_col_1_string}]} ]] && \
                    __blscd_build_array_update
                builtin mapfile -t _blscd_files_col_2_array \
                    < <(builtin printf '%s\n' "${_blscd_data[path $_blscd_dir_col_1_string]//|/}")
                _blscd_files_col_2_array_total=${#_blscd_files_col_2_array[@]}
                ((_blscd_files_col_2_array_total == 0)) && _blscd_files_col_2_array_total=1
                ;;
            3)
                if [[ ${_blscd_data[path ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]} ]]
                then
                    builtin mapfile -t _blscd_files_col_3_array \
                        < <(builtin printf '%s\n' "${_blscd_data[path ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]//|/}")
                else
                    builtin mapfile -t _blscd_files_col_3_array \
                        < <(command find -L "$_blscd_screen_lines_current_string" -mindepth 1 -maxdepth 1 -printf '%f\n' | command sort -bg)
                fi
                _blscd_files_col_3_array_total=${#_blscd_files_col_3_array[@]}
                ((_blscd_files_col_3_array_total == 0)) &&
                {
                    _blscd_files_col_3_array=("$(command file --mime-type -bL "$_blscd_screen_lines_current_string")")
                    _blscd_files_col_3_array=("${_blscd_files_col_3_array[@]//\//-}")
                    _blscd_files_col_3_array_total=1
                }
                ;;
        esac
    done
}

__blscd_build_array_initial()
{
    __blscd_build_array_initial_do()
    {
        builtin declare dir=$1
        _blscd_data[path ${dir}]=$(command find -L "$dir" -mindepth 1 -maxdepth 1 -printf '|%f|\n' | command sort -t '|' -k 2bg)
        #_blscd_data[ls ${dir}]=$(command ls -AblQh --time-style=long-iso "$dir")
        _blscd_data[mark ${dir}]=unmarked
        if [[ ${dir%/*} ]]
        then
            __blscd_build_array_initial_do "${dir%/*}"
        else
            builtin return 0
        fi
    }

    _blscd_data[path /]=$(command find -L "/" -mindepth 1 -maxdepth 1 -printf '|%f|\n' | command sort -t '|' -k 2bg)
    #_blscd_data[ls /]=$(command ls -AblQh --time-style=long-iso /)
    _blscd_data[mark /]=unmarked
    __blscd_build_array_initial_do "$_blscd_dir_col_1_string"

    while builtin read -r -d ''
    do
        _blscd_data[mark ${REPLY}]=unmarked
    done < <(__blscd_list_file)
}

__blscd_build_array_mark_search()
{
    while IFS= builtin read -r -d ''
    do
        [[ $REPLY =~ ^[0-9]*:.*$ ]] && _blscd_data[mark ${REPLY#*:}]=marked && \
            _blscd_files_col_2_array_mark_indexes+=(${REPLY%%:*})
    done < <(__blscd_list_file "$_blscd_search_pattern")

    __blscd_mark_screen_lines_prepare
    __blscd_set_marking_number
}

__blscd_build_array_update()
{
    _blscd_data[path ${_blscd_dir_col_1_string}]=$(command find -L "$_blscd_dir_col_1_string" -mindepth 1 -maxdepth 1 -printf '|%f|\n' | command sort -t '|' -k 2bg)
    #_blscd_data[ls ${_blscd_dir_col_1_string}]=$(command ls -AblQh --time-style=long-iso "$_blscd_dir_col_1_string")
}

__blscd_build_col()
{
    builtin declare i=

    for i
    do
        case $i in
            1a)
                if [[ $_blscd_dir_col_1_string == / ]]
                then
                    _blscd_files_col_1_a_array=(\~)
                    _blscd_highlight_line_col_1_index=0
                elif [[ ${_blscd_data[_blscd_cursor $dir_col_0_string]} ]]
                then
                    builtin mapfile -t _blscd_files_col_1_a_array \
                        < <(builtin printf '%s\n' "${_blscd_files_col_1_array[@]:$((${_blscd_data[_blscd_index $dir_col_0_string]} - 1)):${_blscd_screen_lines_body}}")
                    _blscd_highlight_line_col_1_index=${_blscd_data[_blscd_cursor $dir_col_0_string]}
                else
                    IFS=: builtin read -r _blscd_files_col_1_array_cursor_index _ \
                        < <(builtin printf '%s\n' "${_blscd_files_col_1_array[@]}" | command grep -x -n "${_blscd_dir_col_1_string##*/}")
                    ((--_blscd_files_col_1_array_cursor_index))
                    if ((_blscd_files_col_1_array_cursor_index >= _blscd_screen_lines_body))
                    then
                        _blscd_files_col_1_a_array=("${_blscd_files_col_1_array[@]:$((_blscd_files_col_1_array_cursor_index - _blscd_screen_lines_body + 1)):${_blscd_files_col_1_array_cursor_index}}")
                        _blscd_highlight_line_col_1_index=$((_blscd_screen_lines_body - 1))
                    else
                        _blscd_files_col_1_a_array=("${_blscd_files_col_1_array[@]:0:${_blscd_screen_lines_body}}")
                        _blscd_highlight_line_col_1_index=$_blscd_files_col_1_array_cursor_index
                    fi
                fi
                _blscd_files_col_1_a_array_total=${#_blscd_files_col_1_a_array[@]}
                ;;
            2a)
                [[ $_blscd_search_pattern && ! $_blscd_block == _blscd_block ]] && \
                    __blscd_build_array_mark_search
                if [[ ${_blscd_data[_blscd_cursor $_blscd_dir_col_1_string]} && \
                        $_blscd_action_last != __blscd_move_col_2_line ]]
                then
                     builtin mapfile -t _blscd_files_col_2_a_array \
                        < <(builtin printf '%s\n' "${_blscd_files_col_2_array[@]:$((${_blscd_data[_blscd_index $_blscd_dir_col_1_string]} - 1)):${_blscd_screen_lines_body}}")
                     _blscd_cursor=${_blscd_data[_blscd_cursor $_blscd_dir_col_1_string]}
                     _blscd_index=${_blscd_data[_blscd_index $_blscd_dir_col_1_string]}
                elif [[ $_blscd_dir_col_1_string == / && $_blscd_dir_last ]]
                then
                     builtin mapfile -t _blscd_files_col_2_a_array \
                        < <(builtin printf '%s\n' "${_blscd_files_col_2_array[@]:$((${_blscd_data[_blscd_index $_blscd_dir_last]} - 1)):${_blscd_screen_lines_body}}")
                else
                    _blscd_files_col_2_a_array=("${_blscd_files_col_2_array[@]:$((_blscd_index - 1)):${_blscd_screen_lines_body}}")
                fi
                ;;
            3a)
                if [[ ${_blscd_data[_blscd_cursor ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]} ]]
                then
                    builtin mapfile -t _blscd_files_col_3_a_array \
                        < <(builtin printf '%s\n' "${_blscd_files_col_3_array[@]:$((${_blscd_data[_blscd_index ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]} - 1)):${_blscd_screen_lines_body}}")
                    _blscd_highlight_line_col_3_index=${_blscd_data[_blscd_cursor ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]}
                else
                    _blscd_files_col_3_a_array=("${_blscd_files_col_3_array[@]}")
                    _blscd_highlight_line_col_3_index=0
                fi
                ;;
        esac
    done
}

__blscd_declare_set()
{
    builtin declare -gA _blscd_data

    builtin declare -gi \
        _blscd_cursor=0 \
        _blscd_files_col_1_a_array_total= \
        _blscd_files_col_1_a_array_total= \
        _blscd_files_col_1_array_total= \
        _blscd_files_col_2_array_total= \
        _blscd_files_col_3_array_total= \
        _blscd_highlight_line_col_1_index= \
        _blscd_highlight_line_col_3_index= \
        _blscd_index=1 \
        _blscd_marking_number= \
        _blscd_redraw_number=0 \
        _blscd_screen_lines_body_col_2_visible= \
        _blscd_screen_lines_offset=4

    builtin declare -g \
        _blscd_action_last= \
        _blscd_block= \
        _blscd_dir_col_1_string=$PWD \
        _blscd_dir_last= \
        _blscd_input= \
        _blscd_k1= \
        _blscd_k2= \
        _blscd_k3= \
        _blscd_marking= \
        _blscd_redraw=_blscd_redraw \
        _blscd_reprint=_blscd_reprint \
        _blscd_screen_lines_body= \
        _blscd_screen_lines_current_string= \
        _blscd_screen_lines_header_string=

    builtin declare -ga \
        "_blscd_files_col_1_a_array=()" \
        "_blscd_files_col_1_array=()" \
        "_blscd_files_col_2_a_array=()" \
        "_blscd_files_col_2_array=()" \
        "_blscd_files_col_2_array_mark_indexes=()" \
        "_blscd_files_col_3_a_array=()" \
        "_blscd_files_col_3_array=()"

    # Initialize settings.
    builtin declare -g \
        _blscd_opener='builtin export LESSOPEN='"| /usr/bin/lesspipe %s"';command less -R "$1"' \
        _blscd_search_pattern=

    builtin declare -gi _blscd_INT_step=6

    # Tput configuration.
    {
        builtin declare -g \
            "_blscd_tput_alt=$(command tput smcup || command tput ti)" \
            "_blscd_tput_am_off=$(command tput rmam)" \
            "_blscd_tput_am_on=$(command tput am)" \
            "_blscd_tput_bold=$(command tput bold || command tput md)" \
            "_blscd_tput_clear=$(command tput clear)" \
            "_blscd_tput_cup_1_0=$(command tput cup 1 0)" \
            "_blscd_tput_cup_2_0=$(command tput cup 2 0)" \
            "_blscd_tput_cup_99999_0=$(command tput cup 99999 0)" \
            "_blscd_tput_ealt=$(command tput rmcup || command tput te)" \
            "_blscd_tput_eel=$(command tput el || command tput ce)" \
            "_blscd_tput_hide=$(command tput civis || command tput vi)" \
            "_blscd_tput_home=$(command tput home)" \
            "_blscd_tput_reset=$(command tput sgr0 || command tput me)" \
            "_blscd_tput_show=$(command tput cnorm || command tput ve)" \
            "_blscd_tput_white_f=$(command tput setaf 7 || command tput AF 7)"
    } 2>/dev/null

    [[ $TERM != *-m ]] &&
    {
        builtin declare -g \
            "_blscd_tput_black_f=$(command tput setaf 0)" \
            "_blscd_tput_blue_f=$(command tput setaf 4|| command tput AF 4)" \
            "_blscd_tput_green_b=$(command tput setab 2)" \
            "_blscd_tput_green_f=$(command tput setaf 2 || command tput AF 2)" \
            "_blscd_tput_red_b=$(command tput setab 1)" \
            "_blscd_tput_white_b=$(command tput setab 7)" \
            "_blscd_tput_yellow_b=$(command tput setab 3)"

    } 2>/dev/null

    # Save the terminal environment of the normal screen.
    builtin declare -g \
        "_blscd_saved_stty=$(command stty -g)" \
        "_blscd_saved_traps=$(builtin trap)"
}

__blscd_declare_unset()
{
    builtin unset -v \
        _blscd_action_last \
        _blscd_block \
        _blscd_cursor \
        _blscd_data \
        _blscd_dir_col_1_string \
        _blscd_dir_last \
        _blscd_files_col_1_a_array \
        _blscd_files_col_1_a_array_total \
        _blscd_files_col_1_a_array_total \
        _blscd_files_col_1_array \
        _blscd_files_col_1_array_total \
        _blscd_files_col_2_a_array \
        _blscd_files_col_2_array \
        _blscd_files_col_2_array_mark_indexes \
        _blscd_files_col_2_array_total \
        _blscd_files_col_3_a_array \
        _blscd_files_col_3_array \
        _blscd_files_col_3_array_total \
        _blscd_highlight_line_col_1_index \
        _blscd_highlight_line_col_3_index \
        _blscd_index \
        _blscd_input \
        _blscd_INT_step \
        _blscd_k1 \
        _blscd_k2 \
        _blscd_k3 \
        _blscd_marking \
        _blscd_marking_number \
        _blscd_opener \
        _blscd_redraw \
        _blscd_redraw_number \
        _blscd_reprint \
        _blscd_saved_stty \
        _blscd_saved_traps \
        _blscd_screen_lines_body \
        _blscd_screen_lines_body_col_2_visible \
        _blscd_screen_lines_current_string \
        _blscd_screen_lines_header_string \
        _blscd_screen_lines_offset \
        _blscd_search_pattern \
        _blscd_tput_alt \
        _blscd_tput_am_off \
        _blscd_tput_am_on \
        _blscd_tput_black_f \
        _blscd_tput_blue_f \
        _blscd_tput_bold \
        _blscd_tput_clear \
        _blscd_tput_cup_1_0 \
        _blscd_tput_cup_2_0 \
        _blscd_tput_cup_99999_0 \
        _blscd_tput_ealt \
        _blscd_tput_eel \
        _blscd_tput_green_b \
        _blscd_tput_green_f \
        _blscd_tput_hide \
        _blscd_tput_home \
        _blscd_tput_red_b \
        _blscd_tput_reset \
        _blscd_tput_show \
        _blscd_tput_white_b \
        _blscd_tput_white_f \
        _blscd_tput_yellow_b
}

__blscd_draw_screen()
{
    builtin declare -i \
        i= \
        j= \
        screen_col_1_length= \
        screen_col_2_length= \
        screen_col_3_length= \
        screen_dimension_cols= \
        screen_dimension_lines= \
        _blscd_highlight_line_col_3_index=

    builtin declare \
        dir_col_0_string= \
        footer10_string= \
        footer11_string= \
        footer12_string= \
        footer1_string= \
        footer2_string= \
        footer3_string= \
        footer4_string= \
        footer5_string= \
        footer6_string= \
        footer7_string= \
        footer8_string= \
        footer9_string= \
        screen_lines_body_col_1_color_1= \
        screen_lines_body_col_1_color_reset= \
        screen_lines_body_col_2_color_1= \
        screen_lines_body_col_2_color_mark= \
        screen_lines_body_col_2_color_reset= \
        screen_lines_body_col_3_color_1= \
        screen_lines_body_col_3_color_reset= \
        screen_lines_footer_string=

    # Get dimension.
    builtin read -r screen_dimension_cols screen_dimension_lines \
        <<<$(command tput -S < <(builtin printf '%s\n' cols lines))
    screen_col_1_length=$(((screen_dimension_cols - 2) / 5))
    screen_col_2_length=$((screen_col_1_length * 2))
    screen_col_3_length=$((screen_col_1_length * 2))
    _blscd_screen_lines_body=$((screen_dimension_lines - _blscd_screen_lines_offset + 1))

    # Save directories.
    _blscd_dir_col_1_string=$PWD
    dir_col_0_string=${_blscd_dir_col_1_string%/*}
    dir_col_0_string=${dir_col_0_string:-/}

    if [[ ($_blscd_reprint == _blscd_reprint && $_blscd_action_last != __blscd_move_col_2_line) || \
            ($_blscd_search_pattern && ! $_blscd_block == _blscd_block) || \
            ($_blscd_marking == _blscd_marking && ! $_blscd_block == _blscd_block) ]]
    then
        builtin printf "$_blscd_tput_clear"
        # Build column 1 and 2.
        __blscd_build_array 1 2
        __blscd_build_col 1a 2a
    else
        # Delete obsolete lines in column 3.
        if ((_blscd_files_col_3_array_total <= 15))
        then
            if ((_blscd_files_col_3_array_total < _blscd_screen_lines_body))
            then
                i=$_blscd_files_col_3_array_total
            else
                i=$_blscd_screen_lines_body
            fi
            for ((i=$i ; i > 1 ; --i))
            do
                #command tput cup "$i" "$((screen_col_1_length + screen_col_2_length + 2))"
                builtin printf "\033[$((i + 1));$((screen_col_1_length + screen_col_2_length + 3))H${_blscd_tput_eel}"
                #builtin printf "$_blscd_tput_eel"
            done
        else
            ((_blscd_files_col_3_array_total < _blscd_screen_lines_body && \
                    _blscd_files_col_1_a_array_total > 5)) &&
            {
                builtin printf "$_blscd_tput_cup_2_0"
                for ((i=${_blscd_files_col_3_array_total} ; i < _blscd_screen_lines_body ; ++i))
                do
                    builtin printf "%-${screen_col_1_length}.${screen_col_1_length}s\n" ""
                done
            }
        fi
       __blscd_build_col 2a
    fi

    # Save current line.
    _blscd_screen_lines_current_string=${_blscd_files_col_2_a_array[$_blscd_cursor]}

    # Build column 3.
    __blscd_build_array 3
    __blscd_build_col 3a

    # Save current _blscd_cursor postion, and _blscd_index.
    _blscd_data[_blscd_cursor $_blscd_dir_col_1_string]=$_blscd_cursor
    _blscd_data[_blscd_index $_blscd_dir_col_1_string]=$_blscd_index

    # Preparing for __blscd_move_col_2_line(): Determine the number of visible files.
    if ((_blscd_files_col_2_array_total > _blscd_screen_lines_body))
    then
        _blscd_screen_lines_body_col_2_visible=$_blscd_screen_lines_body
    else
        _blscd_screen_lines_body_col_2_visible=$_blscd_files_col_2_array_total
    fi

    # Print the header.
    if [[ ($_blscd_reprint == _blscd_reprint && $_blscd_action_last != __blscd_move_col_2_line) || \
            $_blscd_search_pattern || $_blscd_marking == _blscd_marking ]]
    then
        builtin printf "$_blscd_tput_home"
        [[ $_blscd_block == _blscd_block ]] && builtin printf "$_blscd_tput_eel"
        builtin printf -v _blscd_screen_lines_header_string "${_blscd_tput_blue_f}${_blscd_tput_bold}%s@%s:${_blscd_tput_green_f}%s/${_blscd_tput_white_f}%s" \
                "$USER" "$HOSTNAME" "$PWD" "$_blscd_screen_lines_current_string"
    else
        if [[ $_blscd_dir_col_1_string == / ]]
        then
            #command tput cup 0 "$((${#USER} + ${#HOSTNAME} + ${#_blscd_dir_col_1_string} + 2))"
            builtin printf "\033[0;$((${#USER} + ${#HOSTNAME} + ${#_blscd_dir_col_1_string} + 3))H"
        else
            #command tput cup 0 "$((${#USER} + ${#HOSTNAME} + ${#_blscd_dir_col_1_string} + 3))"
            builtin printf "\033[0;$((${#USER} + ${#HOSTNAME} + ${#_blscd_dir_col_1_string} + 4))H"
        fi
        builtin printf -v _blscd_screen_lines_header_string "${_blscd_tput_eel}${_blscd_tput_bold}${_blscd_tput_white_f}%s" "$_blscd_screen_lines_current_string"
    fi
    builtin printf '%s\n' "${_blscd_screen_lines_header_string//\/\//\/}"
    builtin printf "$_blscd_tput_reset"

    # Print columns with file listing and highlight lines.
    builtin printf "$_blscd_tput_cup_1_0"
    for ((i=0 ; i <= _blscd_screen_lines_body ; ++i))
    do
        screen_lines_body_col_1_color_1=
        screen_lines_body_col_1_color_reset=
        screen_lines_body_col_2_color_1=
        screen_lines_body_col_2_color_reset=
        screen_lines_body_col_2_color_mark=
        screen_lines_body_col_3_color_1=
        screen_lines_body_col_3_color_reset=

        ((i == _blscd_highlight_line_col_1_index)) &&
        {
            screen_lines_body_col_1_color_1=${_blscd_tput_bold}${_blscd_tput_black_f}${_blscd_tput_green_b}
            screen_lines_body_col_1_color_reset=$_blscd_tput_reset
        }

        ((i == _blscd_cursor)) &&
        {
            if [[ -d $_blscd_screen_lines_current_string ]]
            then
                screen_lines_body_col_2_color_1=${_blscd_tput_bold}${_blscd_tput_black_f}${_blscd_tput_green_b}
            elif [[ -f $_blscd_screen_lines_current_string ]]
            then
                screen_lines_body_col_2_color_1=${_blscd_tput_bold}${_blscd_tput_black_f}${_blscd_tput_white_b}
            else
                screen_lines_body_col_2_color_1=${_blscd_tput_bold}${_blscd_tput_white_f}${_blscd_tput_red_b}
            fi
            screen_lines_body_col_2_color_reset=$_blscd_tput_reset
        }

        ((i == _blscd_highlight_line_col_3_index)) &&
        {
            if [[ -d ${_blscd_screen_lines_current_string}/${_blscd_files_col_3_a_array[$i]} ]]
            then
                screen_lines_body_col_3_color_1=${_blscd_tput_bold}${_blscd_tput_black_f}${_blscd_tput_green_b}
            elif [[ -f ${_blscd_screen_lines_current_string}/${_blscd_files_col_3_a_array[$i]} ]]
            then
                screen_lines_body_col_3_color_1=${_blscd_tput_bold}${_blscd_tput_black_f}${_blscd_tput_white_b}
            else
                screen_lines_body_col_3_color_1=${_blscd_tput_bold}${_blscd_tput_white_f}${_blscd_tput_red_b}
            fi
            screen_lines_body_col_3_color_reset=$_blscd_tput_reset
        }

        [[ $_blscd_search_pattern || $_blscd_marking == _blscd_marking ]] &&
        {
            [[ ${_blscd_data[mark ${_blscd_dir_col_1_string}/${_blscd_files_col_2_a_array[$i]}]} == marked ]] &&
            {
                screen_lines_body_col_2_color_mark=${_blscd_tput_bold}${_blscd_tput_black_f}${_blscd_tput_yellow_b}
                screen_lines_body_col_2_color_reset=$_blscd_tput_reset
            }
        }
        builtin printf "${screen_lines_body_col_1_color_1}%-${screen_col_1_length}.${screen_col_1_length}s${screen_lines_body_col_1_color_reset} ${screen_lines_body_col_2_color_mark}${screen_lines_body_col_2_color_1}%-${screen_col_2_length}.${screen_col_2_length}s${screen_lines_body_col_2_color_reset} ${screen_lines_body_col_3_color_1}%-${screen_col_3_length}.${screen_col_3_length}s${screen_lines_body_col_3_color_reset}\n" " ${_blscd_files_col_1_a_array[$i]} " " ${_blscd_files_col_2_a_array[$i]} " " ${_blscd_files_col_3_a_array[$i]} "
    done

    # Print the footer.
    builtin printf "${_blscd_tput_blue_f}${_blscd_tput_bold}"

    builtin read -r footer1_string footer2_string footer3_string footer4_string \
            footer5_string footer6_string footer7_string _ _ footer8_string \
        <<<$(command ls -abdlQh --time-style=long-iso "${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}")

    [[ -d ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string} ]] && \
        footer5_string=$_blscd_files_col_3_array_total

    builtin read -r footer9_string footer10_string footer11_string \
        <<<"$((_blscd_index + _blscd_cursor)) ${_blscd_files_col_2_array_total} \
        $(((100 * (_blscd_index + _blscd_cursor)) / _blscd_files_col_2_array_total))"

    if [[ $_blscd_search_pattern || $_blscd_marking == _blscd_marking ]]
    then
        footer12_string="${_blscd_marking_number} Mrk"
    elif ((_blscd_files_col_2_array_total <= _blscd_screen_lines_body))
    then
        footer12_string=All
    elif ((_blscd_files_col_2_array_total > _blscd_screen_lines_body && \
            _blscd_cursor + _blscd_index <= _blscd_screen_lines_body_col_2_visible))
    then
        footer12_string=Top
    elif ((_blscd_files_col_2_array_total > _blscd_screen_lines_body && \
        _blscd_cursor + _blscd_index >= _blscd_files_col_2_array_total - _blscd_screen_lines_body + 1))
    then
        footer12_string=Bot
    else
        footer12_string=Mid
    fi

    #command tput cup "$((_blscd_screen_lines_body + 1))" 0
    builtin printf "\033[$((_blscd_screen_lines_body + 2));0H${_blscd_tput_eel}"
    #builtin printf "$_blscd_tput_eel"

    builtin printf -v screen_lines_footer_string "%s %s %s %s %s %s %s${footer8_string:+ -> %s}  %s/%s  %d%% %s" \
            "$footer1_string" "$footer2_string" "$footer3_string" "$footer4_string" "$footer5_string" \
            "$footer6_string" "$footer7_string" ${footer8_string:+"${footer8_string}"} "$footer9_string" \
            "$footer10_string" "$footer11_string" "$footer12_string"

    builtin printf "%s${_blscd_tput_reset} %s %s %s %s %s${footer8_string:+ %s ->} %-$((screen_dimension_cols - ${#screen_lines_footer_string} + ${#footer7_string} ${footer8_string:++ $((${#footer8_string} - ${#footer7_string}))}))s  %s/%s  %d%% %s" "$footer1_string" "$footer2_string" "$footer3_string" "$footer4_string" "$footer5_string" "$footer6_string" "$footer7_string" ${footer8_string:+"${footer8_string}"} "$footer9_string" "$footer10_string" "$footer11_string" "$footer12_string"

    # Set new position of the _blscd_cursor.
    #builtin printf "$_blscd_tput_reset"
    #command tput cup "$((_blscd_cursor + 1))" "$((screen_col_1_length + 1))"
    builtin printf "${_blscd_tput_reset}\033[$((_blscd_cursor + 2));$((screen_col_1_length + 2))H"
}

__blscd_list_file()
{
    __blscd_list_file_find()
    {
        command find -L "$_blscd_dir_col_1_string" -mindepth 1 -maxdepth 1 \
                \( -xtype l -type d -printf '%h/%f\0' \) \
                -o \( -xtype l -type f -printf '%h/%f\0' \) \
                -o \( -xtype d -type d -printf '%h/%f\0' \) \
                -o \( -xtype f -type f -printf '%h/%f\0' \) | \
            command sort -zbg
    }

    if [[ $1 ]]
    then
        __blscd_list_file_find | command egrep --null-data -n -C 9999999 -e "$1"
    else
        __blscd_list_file_find
    fi
}

__blscd_mark_go_down()
{
    builtin declare -i i=

    for i in "${_blscd_files_col_2_array_mark_indexes[@]}"
    do
        ((i > _blscd_index + _blscd_cursor)) &&
        {
            __blscd_move_col_2_line "$((i - _blscd_index - _blscd_cursor))"
            builtin break
        }
    done
}

__blscd_mark_go_up()
{
    declare -i i=

    for (( i=${#_blscd_files_col_2_array_mark_indexes[@]}-1 ; i >= 0 ; i--))
    do
        ((${_blscd_files_col_2_array_mark_indexes[$i]} < _blscd_index + _blscd_cursor)) &&
        {
            __blscd_move_col_2_line "-$((_blscd_cursor + _blscd_index - ${_blscd_files_col_2_array_mark_indexes[$i]}))"
            builtin break
        }
    done
}

__blscd_mark_screen_lines_all()
{
    builtin declare -i i=0

    while IFS= builtin read -r -d ''
    do
        if [[ ${_blscd_data[mark ${REPLY}]} == marked ]]
        then
            _blscd_data[mark ${REPLY}]=unmarked
        elif [[ ${_blscd_data[mark ${REPLY}]} == unmarked ]]
        then
            _blscd_data[mark ${REPLY}]=marked
        fi
    done < <(__blscd_list_file)

    #__blscd_mark_screen_lines_prepare
    __blscd_set_marking_number
}

__blscd_mark_screen_lines_all_unmark()
{
    builtin declare i=

    for i in "${!_blscd_data[@]}"
    do
        [[ $i =~ ^mark..*$ ]] && \
            [[ ${_blscd_data[$i]} == marked ]] && \
            _blscd_data[$i]=unmarked
    done
}

__blscd_mark_screen_lines_current()
{
    if [[ ${_blscd_data[mark ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]} == marked ]]
    then
         _blscd_data[mark ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]=unmarked
    elif [[ ${_blscd_data[mark ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]} == unmarked ]]
    then
        _blscd_data[mark ${_blscd_dir_col_1_string}/${_blscd_screen_lines_current_string}]=marked
    fi
    #__blscd_mark_screen_lines_prepare
    __blscd_set_marking_number
}

__blscd_mark_screen_lines_prepare()
{
    __blscd_mark_screen_lines_prepare_order_num_asc()
    {
        builtin declare -a "array=()"
        builtin declare \
            i= \
            j= \
            element=

        array=($@)
        for ((i=1 ; i < ${#array[@]} ; ++i))
        do
            for ((j=i ; j > 0 ; --j))
            do
                element=${array[j]}
                ((${element%%,*} < ${array[j-1]%%,*})) && \
                    { array[j]=${array[j-1]} ; array[j-1]=$element ; }
            done
        done
        builtin printf '%s\n' "${array[@]}"
    }

    __blscd_mark_screen_lines_prepare_uniq()
    {
        builtin declare -a "array1=()"
        builtin declare -A array2
        builtin declare i=

        array1=($@)
        for i in "${array1[@]}"
        do
            array2[$i]=$i
        done
        builtin printf '%s\n' "${array2[@]}"
    }

    builtin mapfile -t _blscd_files_col_2_array_mark_indexes \
        < <(__blscd_mark_screen_lines_prepare_order_num_asc \
            "$(__blscd_mark_screen_lines_prepare_uniq \
            "$(__blscd_mark_screen_lines_prepare_order_num_asc \
            "${_blscd_files_col_2_array_mark_indexes[@]}")")")
}

__blscd_move_col_2_line()
{
    __blscd_set_action_last

    builtin declare -i \
        arg=$1 \
        difference= \
        max_cursor=$((_blscd_screen_lines_body_col_2_visible - 1)) \
        max_index=$((_blscd_files_col_2_array_total - _blscd_screen_lines_body_col_2_visible + 1)) \
        old_index=$_blscd_index \
        step=

    _blscd_redraw=_blscd_redraw

    # Add the argument to the current _blscd_cursor
    _blscd_cursor=$((_blscd_cursor + arg))

    if ((_blscd_cursor >= _blscd_screen_lines_body_col_2_visible))
    then
        # _blscd_cursor moved past the bottom of the list.
        if ((_blscd_screen_lines_body_col_2_visible >= _blscd_files_col_2_array_total))
        then
            # The list fits entirely on the screen.
            _blscd_index=1
        else
            # The list doesn't fit on the screen.
            if ((_blscd_index + _blscd_cursor > _blscd_files_col_2_array_total))
            then
                # _blscd_cursor out of bounds. Put it at the very bottom.
                _blscd_index=$max_index
            else
                # Move the _blscd_index down so the visible part of the list,
                # also shows the _blscd_cursor.
                difference=$((_blscd_screen_lines_body_col_2_visible - 1 - _blscd_cursor))
                _blscd_index=$((_blscd_index - difference))
            fi
        fi
        # In any case, place the _blscd_cursor on the last file.
        _blscd_cursor=$max_cursor
    elif ((_blscd_cursor <= 0))
    then
        # _blscd_cursor is above the list, so scroll up.
        _blscd_index=$((_blscd_index + _blscd_cursor))
        _blscd_cursor=0
    fi

    # The _blscd_index should always be >0 and <$max_index.
    ((_blscd_index > max_index)) && _blscd_index=$max_index
    ((_blscd_index < 1)) && _blscd_index=1

    ((_blscd_index != old_index)) &&
    {
        # _blscd_redraw if the _blscd_index (and thus the visible files) has changed.
        _blscd_reprint=_blscd_reprint

        # Jump a step when scrolling.
        if ((_blscd_index > old_index))
        then
            # Jump a step down.
            step=$((max_index - _blscd_index))
            ((step > _blscd_INT_step)) && step=$_blscd_INT_step
            _blscd_index=$((_blscd_index + step))
            _blscd_cursor=$((_blscd_cursor - step))
        else
            # Jump a step up.
            step=$((_blscd_index - 1))
            ((step > _blscd_INT_step)) && step=$_blscd_INT_step
            _blscd_index=$((_blscd_index - step))
            _blscd_cursor=$((_blscd_cursor + step))
        fi
    }

    # The _blscd_index should always be >0 and <$max_index.
    ((_blscd_index > max_index)) && _blscd_index=$max_index
    ((_blscd_index < 1)) && _blscd_index=1
}

__blscd_move_dir()
{
    __blscd_set_resize 1

    __blscd_move_dir_up()
    {
        __blscd_set_action_last
        _blscd_index=1
        _blscd_cursor=0
    }

    __blscd_move_dir_down()
    {
        __blscd_set_action_last
        _blscd_index=1
        _blscd_cursor=0
    }

    if [[ $1 == .. ]]
    then
         __blscd_move_dir_up
    else
         __blscd_move_dir_down
    fi

    _blscd_dir_last=$_blscd_dir_col_1_string
    builtin cd -- "$1"
}

__blscd_on_exit()
{
    command stty $_blscd_saved_stty
    builtin eval "$_blscd_saved_traps"
    builtin printf "${_blscd_tput_clear}${_blscd_tput_ealt}${_blscd_tput_show}${_blscd_tput_am_on}"
    __blscd_declare_unset
}

__blscd_open_file()
{
    case $(command file --mime-type -bL "$1") in
        inode/directory)
                 __blscd_move_dir "$1"
            ;;
        *)
            __blscd_set_action_last
            builtin eval "$_blscd_opener" 2>/dev/null
            ;;
    esac
}

__blscd_reload()
{
    __blscd_search_marking_non
    _blscd_redraw_number=0
    builtin unset -v _blscd_data
    builtin declare -gA _blscd_data
}

__blscd_search()
{
    __blscd_set_action_last
    _blscd_block=
    builtin printf "$_blscd_tput_cup_99999_0"
    command stty $_blscd_saved_stty
    builtin read -e -p "/" -i "$_blscd_search_pattern" _blscd_search_pattern
    command stty -echo
}

__blscd_search_marking_non()
{
    _blscd_search_pattern=
    _blscd_block=
    _blscd_marking=
    _blscd_files_col_2_array_mark_indexes=()
}

__blscd_set_action_last() { _blscd_action_last=${FUNCNAME[1]} ; }

__blscd_set_marking_number()
{
    _blscd_marking_number=0

    while builtin read -r -d ''
    do
        [[ ${_blscd_data[mark ${REPLY}]} == marked ]] && ((++_blscd_marking_number))
    done < <(__blscd_list_file)

    if ((_blscd_marking_number == 0))
    then
        __blscd_search_marking_non
    else
        _blscd_marking=_blscd_marking
        _blscd_block=_blscd_block
    fi
}

__blscd_set_resize()
{
    if (($1 == 1))
    then
        _blscd_redraw=_blscd_redraw
        _blscd_reprint=_blscd_reprint
    else
        _blscd_redraw=
        _blscd_reprint=
    fi
}

# -- MAIN.

# Global Declaration.
__blscd_declare_set

# Go to the alternate screen and change the terminal enviroment.
builtin printf "$_blscd_tput_alt"
command stty -echo

#trap 'printf "$_blscd_tput_ealt"' EXIT
builtin trap '__blscd_set_resize 1' SIGWINCH
builtin trap 'printf "$_blscd_tput_clear"' SIGINT

builtin export LC_ALL=C.UTF-8

while builtin :
do
    builtin printf "${_blscd_tput_hide}${_blscd_tput_am_off}"
    ((_blscd_redraw_number == 0)) && __blscd_build_array_initial
    [[ $_blscd_redraw == _blscd_redraw ]] &&
    {
        __blscd_draw_screen
        __blscd_set_resize 0
        ((++_blscd_redraw_number))
    }
    builtin read -s -n 1 _blscd_input
    builtin read -s -N 1 -t 0.0001 _blscd_k1
    builtin read -s -N 1 -t 0.0001 _blscd_k2
    builtin read -s -N 1 -t 0.0001 _blscd_k3
    _blscd_input=${_blscd_input}${_blscd_k1}${_blscd_k2}${_blscd_k3}
    case $_blscd_input in
        j|$'\e[B')
            __blscd_move_col_2_line 1
            ;;
        k|$'\e[A')
            __blscd_move_col_2_line -1
            ;;
        h|$'\e[D')
            __blscd_move_dir ..
            ;;
        l|$'\e[C')
            __blscd_open_file "$_blscd_screen_lines_current_string"
            builtin printf "$_blscd_tput_alt"
            __blscd_set_resize 1
            ;;
        $'\x06'|$'\e[6~') # Ctrl-F
            __blscd_move_col_2_line "${_blscd_screen_lines_body}"
            ;;
        $'\x02'|$'\e[5~') # Ctrl-B
             __blscd_move_col_2_line "-${_blscd_screen_lines_body}"
            ;;
        $'\e[H') # <HOME>
            __blscd_move_col_2_line -9999999999
            ;;
        G|$'\e[F') # <END>
            __blscd_move_col_2_line 9999999999
            ;;
        J)
            __blscd_move_col_2_line "$((_blscd_screen_lines_body / 2))"
            ;;
        K)
            __blscd_move_col_2_line "-$((_blscd_screen_lines_body / 2))"
            ;;
        d)
            __blscd_move_col_2_line 5
            ;;
        D)
            __blscd_move_col_2_line 10
            ;;
        u)
            __blscd_move_col_2_line -5
            ;;
        U)
            __blscd_move_col_2_line -10
            ;;
        g)
            builtin read -n 1 _blscd_input
            case $_blscd_input in
                g)
                    __blscd_move_col_2_line -9999999999 ;;
                h)
                    __blscd_move_dir ~ ;;
                e)
                    __blscd_move_dir "/etc" ;;
                u)
                    __blscd_move_dir "/usr" ;;
                d)
                    __blscd_move_dir "/dev" ;;
                l)
                    __blscd_move_dir "/usr/lib" ;;
                L)
                    __blscd_move_dir "/var/log" ;;
                o)
                    __blscd_move_dir "/opt" ;;
                v)
                    __blscd_move_dir "/var" ;;
                m)
                    __blscd_move_dir "/media" ;;
                M)
                    __blscd_move_dir "/mnt" ;;
                s)
                    __blscd_move_dir "/srv" ;;
                r|/)
                    __blscd_move_dir / ;;
                \?)
                    __blscd_help ;;
            esac
            ;;
        "")
            __blscd_mark_screen_lines_current
            __blscd_set_resize 1
            __blscd_move_col_2_line 1
            ;;
        v)
            builtin read -n 1 _blscd_input
            case $_blscd_input in
                n)
                    __blscd_mark_screen_lines_all_unmark
                    __blscd_search_marking_non
                    ;;
                v)
                    __blscd_mark_screen_lines_all
                    ;;
            esac
            __blscd_set_resize 1
            ;;
        /)
            builtin printf "${_blscd_tput_show}${_blscd_tput_am_on}"
            __blscd_search
            __blscd_set_resize 1
            __blscd_move_col_2_line -9999999999
            ;;
        n)
            __blscd_mark_go_down
            ;;
        m)
            __blscd_mark_go_up
            ;;
        R)
            __blscd_reload
            ;&
        $'\x0c') # CTRL+L
            __blscd_set_resize 1
            ;;
        q)
            __blscd_reload
            __blscd_on_exit
            builtin break
            ;;
    esac
done
