#!/bin/bash

# Default values
folder="."
if [ -n "$1" ]; then
    folder="$1"
fi

N=0
if [ -n "$2" ]; then
    N="$2"
fi

total_files=0

#Validate fasta
validate_fasta() {
    file=$1
    valid=0 #Since we can not use return, I made a DIY return
    [[ $(grep '^>' "$file") ]] || valid=1
    [[ $(grep -v '^>' "$file" | grep '[ACGTUNacgtunARNDCEQGHILKMFPSTWYVarnqceqghilkmfpstwyv]*') ]] || valid=1
    [[ -s "$file" ]] || valid=1
}

# Process files in the given folder (and subfolders)
for file in $(find "$folder" -type f -name "*.fasta" -o -name "*.fa"); do
    validate_fasta "$file"
    if [[ $valid -eq 1 ]]; then
        echo "Error: $file is an invalid FASTA file. Skipping..."
        echo "-------------------------------"
        continue
    fi

    total_files=$((total_files + 1))
    
    # Fasta IDs
    all_ids+=$(awk '/^>/{print $1}' "$file" | sort | uniq)
    
    # Symlink
    if [ -L "$file" ]; then
        symlink="Yes"
    else
        symlink="No"
    fi

    # Header
    echo "=== File: $file ==="
    echo "Is this a symlink: $symlink"
    echo "-------------------------------"
done

total_unique_ids=$(echo "$all_ids" | sort | uniq | wc -l)

echo "=== Process summary ==="
echo "Total files processed: $total_files"
echo "Total unique fasta IDs: $total_unique_ids"
