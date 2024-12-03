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

# Temporary file to store IDs
temp_ids=$(mktemp)

# Process files in the given folder and its subfolders
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

    # Extract FASTA IDs and add them to the temporary file
    awk '/^>/{print $1}' "$file" >> "$temp_ids"

    # Clean the temporary file progressively (sort and remove duplicates)
    sort -u -o "$temp_ids" "$temp_ids"

    # Process file content
    cleaned_file=$(awk '/^[^>]/ {gsub(/[-\t\r\v\f]/, ""); ORS=""; print $0}' "$file")
    num_sequences=$(grep -c '^>' "$file")
    total_length=${#cleaned_file}

    if [[ $cleaned_file =~ ^[ACGTUN-]*$ ]]; then
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
total_unique_ids=$(wc -l < "$temp_ids")

# Final summary
echo "=== Process summary ==="
echo "Total files processed: $total_files"
echo "Total unique fasta IDs: $total_unique_ids"

# Clean up temporary file
rm -f "$temp_ids"
