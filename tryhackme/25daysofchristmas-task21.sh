#!/usr/bin/env bash

# Solution to Task 21 (Day 16: File Confusion) in bash instead of suggested python
# Pass file as first argument

outdir=$(mktemp -d)
cp $1 $outdir

stop=0
while [ $stop -eq 0 ]
do
    zips=$(find $outdir -name "*.zip")
    if [ ${#zips} -eq 0 ]
    then
        stop=1
    else
        for file in $zips
        do
            7z e -bd -o$outdir $file 1>/dev/null
            rm $file
        done
    fi
done

# part 1
echo file count: $(ls -1 $outdir 2>/dev/null | wc -l)

# part 2
versioned=$(grep -R -i "Version" $outdir | wc -l)
echo versioned files: $versioned

# part 3
echo password file: $(find $outdir/ -type f -exec grep -l "password" {} \;)

rm -r $outdir