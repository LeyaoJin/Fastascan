#!/bin/bash

# Default folder and number of lines to display
folder="."
if [ -n "$1" ]; then
    folder="$1"
fi

N=0
if [ -n "$2" ]; then
    N="$2"
fi

total_files=0
all_ids=""

# Process files in the given folder and subfolders
find "$folder" -type f \( -name "*.fasta" -o -name "*.fa" \) | while read -r file; do

    # Validate FASTA file
    if [[ ! -s "$file" ]]; then
        echo "Error: $file is an empty FASTA file. Skipping..."
        echo "-------------------------------"
        continue
    fi

    if ! grep -q '^>' "$file"; then
        echo "Error: $file is an invalid FASTA file. Missing headers. Skipping..."
        echo "-------------------------------"
        continue
    fi

    if grep -v '^>' "$file" | grep -i -q -v '^[ACGTUNRDEQHILKMFPSWYXV-]*$'; then
        echo "Error: $file contains invalid characters in sequences. Skipping..."
        echo "-------------------------------"
        continue
    fi

    # Increment valid file count
    total_files=$((total_files + 1))

    # Extract IDs and sort/unique them progressively
    all_ids+=$(awk '/^>/{print $1}' "$file" | sort | uniq)

    # Process file content
    cleaned_file=$(awk '/^[^>]/ {gsub(/[-\t\r\v\f]/, ""); ORS=""; print $0}' "$file")
    num_sequences=$(grep -c '^>' "$file")
    total_length=$(echo -n "$cleaned_file" | wc -c)

    if echo "$cleaned_file" | grep -q '^[ACGTUN-]*$'; then
        file_type="Nucleotides"
    else
        file_type="Amino acids"
    fi

    # File summary
    echo "=== File: $file ==="
    echo "Number of sequences: $num_sequences"
    echo "Total sequence length: $total_length"
    echo "File type: $file_type"
    echo "-------------------------------"

    # Display file content based on N
    if [[ $N -gt 0 ]]; then
        total_lines=$(wc -l < "$file")
        if [[ $total_lines -le $((2 * N)) ]]; then
            cat "$file"
        else
            head -n $N "$file"
            echo "..."
            tail -n $N "$file"
        fi
    fi
done

# Count total unique IDs
if [[ -n "$all_ids" ]]; then
    total_unique_ids=$(echo "$all_ids" | sort | uniq |wc -l)
else
    total_unique_ids=0
fi

# Final summary
echo "=== Process summary ==="
echo "Total files processed: $total_files"
echo "Total unique fasta IDs: $total_unique_ids"

