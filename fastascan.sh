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
total_unique_ids=0

# Process files in the given folder (and subfolders)
for file in $(find "$folder" -type f -name "*.fasta" -o -name "*.fa"); do
    total_files=$((total_files + 1))
    
    # Fasta IDs
    unique_ids=$(awk '/^>/{print $1}' "$file" | sort | uniq | wc -l)
    total_unique_ids=$((total_unique_ids + unique_ids))
    
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

echo "=== Process summary ==="
echo "Total files processed: $total_files"
echo "Total unique fasta IDs: $total_unique_ids"
