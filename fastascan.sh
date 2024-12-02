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

# Process files in the given folder (and subfolders)
for file in $(find "$folder" -type f -name "*.fasta" -o -name "*.fa"); do

    #Validate fasta
    if ! [[ -s "$file" ]]; then
        echo "Error: $file is an empty FASTA file. Skipping..."
        echo "-------------------------------"
        continue
    elif ! [[ $(grep '^>' "$file") ]]; then
        echo "Error: $file is an invalid FASTA file without headers. Skipping..."
        echo "-------------------------------"
        continue
    elif ! [[ $(grep -v '^>' "$file" | grep -i '[ACGTUNRDEQHILKMFPSWYV]*') ]]; then
        echo "Error: $file is an invalid FASTA file without sequences. Skipping..."
        echo "-------------------------------"
        continue
    fi

    #Total files counter
    total_files=$((total_files + 1))

    # Fasta IDs
    all_ids+=$(awk '/^>/{print $1}' "$file" | sort | uniq)

    # Symlink
    if [ -L "$file" ]; then
        symlink="Yes"
    else
        symlink="No"
    fi

    #Number of sequences en total length
    num_sequences=$(grep -c '^>' "$file")
    total_length=$(awk 'NF>0 && /^[^>]/ {ORS=""; print $0}' "$file" | sed 's/-//g' | wc -c)

    # Determine if it's nucleotide or amino acid
    if [[ $(grep -v '^>' "$file" | grep -i '[ACGTUN]*') ]]; then
        file_type="Nucleotides"
    else
        file_type="Amino acids"
    fi

    # Header
    echo "=== File: $file ==="
    echo "Is this a symlink: $symlink"
    echo "Number of sequences: $num_sequences"
    echo "Total sequence length: $total_length"
    echo "-------------------------------"
done

total_unique_ids=$(echo "$all_ids" | sort | uniq | wc -l)

echo "=== Process summary ==="
echo "Total files processed: $total_files"
echo "Total unique fasta IDs: $total_unique_ids"
