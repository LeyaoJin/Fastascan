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
    if [[ ! $(grep -q '^>' "$file") ]]; then
        echo "Error, invalid FASTA file: $file"
        return 1 
    fi

    if [[ $(grep -q '[^ACGTNacgtnARNDCEQGHILKMFPSTWYVarnqceqghilkmfpstwyv]' "$file") ]]; then
        echo "Error, file contains invalid characters: $file"
        return 1  
    fi

    # Check if the file is empty
    if [[ ! -s "$file" ]]; then
        echo "Error, empty file: $file"
        return 1 
    fi

    # If all checks pass, return 0 (valid file)
    return 0
}

# Process files in the given folder (and subfolders)
for file in $(find "$folder" -type f -name "*.fasta" -o -name "*.fa"); do
    if [[ ! validate_fasta "$file" ]]; then
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
