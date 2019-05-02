#!/bin/sh

# mangaSplit.sh
# Simple tool to split double wide manga images to fit better on ereaders/tablets
# Usage: ./mangaSplit.sh {source} {output}
# Source should be a directory with chapters split into subfolders
# Output will be a directory with chapters split into subfolders containing the split pages
# AND a cbz file with the same directory structure
# TODO: Add params to create a cbz/cbr or neither
#	Handle images at the source root
#       Clean up the code to reorder the pages
#       Clean up/remove the code to re-add the credits page
#       Think of a better name
INPUT=$1
OUTPUT=$2

cd "$INPUT"
for img in */*.jpg
do
    echo $img

    DR=${img%/*}

    if [ ! -d "$OUTPUT/$DR" ]; then
        mkdir "$OUTPUT/$DR"
    fi

    # Some manga stores covers as single pages.
    # For this project, single pages are ~680px wide
    # So only split when Width > 700
    W=$(identify -format "%w" "$img")> /dev/null

    if [ $W -gt 700 ]
    then
        # Standard Page, Convert
        # ImageMagick split in two files of equal width
        convert "$img" -crop 2x1@ +repage "$OUTPUT/$img"
    else
        #Cover Page, copy
        cp "$img" "$OUTPUT/$DR"
    fi
done

# I Hate this
# To keep the translator credits page intact
# Delete the split version and replace with the raw version
# This is due to the loop picking files out of alpha-numeric order
cd "$OUTPUT"

for D in */; do
    cd "$D"
    LF=$(ls | sort -V | tail -n 1)
    rm $LF
    LF=$(ls | sort -V | tail -n 1)
    rm $LF
    cd "$INPUT/$D"
    LF=$(ls | sort -V | tail -n 1)
    cp $LF "$OUTPUT/$D"
    cd "$OUTPUT"
done

# I hate this even more
# Since manga is read from right to left
# Flip the order of the split pages
for file in */*0.jpg; do mv "$file" "${file/0.jpg/b.jpg}"; done
for file in */*1.jpg; do mv "$file" "${file/1.jpg/a.jpg}"; done
for file in */*a.jpg; do mv "$file" "${file/a.jpg/0.jpg}"; done
for file in */*b.jpg; do mv "$file" "${file/b.jpg/1.jpg}"; done

# Finally, compress it to a CBZ
NAME="${OUTPUT##*/}"
zip -r -X "../$NAME".cbz *
echo "$NAME.cbz created"
