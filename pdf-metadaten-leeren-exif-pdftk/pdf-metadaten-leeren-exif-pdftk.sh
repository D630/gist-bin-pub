#!/usr/bin/env bash

# Remove PDF metadata with pdftk and exiftool

shopt -s nocaseglob

[[ -e ./tmp ]] && { echo "There is already a tmp dir." 1>&2 ; exit 1 ; }
[[ -e ./pdf_new ]] && { echo "There is already a pdf_new dir." 1>&2 ; exit 1 ; }

mkdir -- ./tmp ./pdf_new
cp -- ./*.pdf ./tmp

while IFS= read -d '' -r
do
    filename=$(basename "$REPLY")

    # remove XMP-Metadata incrementell
    exiftool -all= "$REPLY"

    # then rewrite PDF
    pdftk "$REPLY" dump_data | sed -r -e 's/^(InfoValue:).*/\1/g' | pdftk "$REPLY" update_info - output "./pdf_new/${filename}" 2>/dev/null
done < <(find ./tmp -type f -iname "*.pdf" -print0)

rm -r -- ./tmp
