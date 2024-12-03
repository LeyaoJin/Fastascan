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

all_ids=""

# Process files in the given folder (and subfolders)
for file in $(find "$folder" -type f -name "*.fasta" -o -name "*.fa"); do

    #Validate fasta file
    if ! [[ -s "$file" ]]; then
        echo "Error: $file is an empty FASTA file. Skipping..."
        echo "-------------------------------"
        continue
    elif ! [[ $(grep '^>' "$file") ]]; then
        echo "Error: $file is an invalid FASTA file due to incorrect format or missing headers. Skipping..."
        echo "-------------------------------"
        continue
    elif [[ $(grep -v '^>' "$file" | grep -i -v '^[ACGTUNRDEQHILKMFPSWYXV-]*$') ]]; then
# Translation: If there are any characters after greping out the headers and the letters that matches with sequences of amino acis and nucleotides, then
        echo "Error: $file is an invalid FASTA file without sequences or the sequences contain invalid characters. Skipping..."
        echo "-------------------------------"
        continue
    fi

    #Total files counter
    total_files=$((total_files + 1))

    # Fasta IDs counter
    all_ids+=$(awk '/^>/{print $1}' "$file" | sort | uniq)

    # Symlink
    if [[ -h "$file" ]]; then
        symlink="Yes"
    else
        symlink="No"
    fi

    # Variable to store the content of the file without gaps, spaces and new line characters
    cleaned_file=$(awk '/^[^>]/ {gsub(/[-\t\r\v\f]/, "", $0); ORS=""; print $0}' "$file")

    # Number of sequences
    num_sequences=$(grep -c '^>' "$file")

    # Total length
    total_length=$(echo -n "$cleaned_file" | wc -c)

# Comment!: After storaging the cleaned file in the variable,
# when it does echo it adds a new line or something that counts as another character,
# It was tried to solve that using sed with [:space:] and also with [-\t\r\v\n\f] but it didn't work, so that is why echo -n is used

    # To determine if it's nucleotide or amino acid
    if  [[ $(echo -n "$cleaned_file" | grep -i '^[ACGTUN-]*$') ]]; then
        file_type="Nucleotides"
    else
        file_type="Amino acids"
    fi

    # Header
    echo "=== File: $file ==="
    echo "Is this a symlink: $symlink"
    echo "Number of sequences: $num_sequences"
    echo "Total sequence length: $total_length"
    echo "File type: $file_type"
    echo "-------------------------------"

    # Show content based on number of lines
    if [[ $N -gt 0 ]]; then
        total_lines=$(cat "$file" | wc -l)
        if [[ $total_lines -le $((2 * N)) ]]; then
            cat "$file"
        else
            head -n $N "$file"
            echo "..."
            tail -n $N "$file"
        fi
    fi
done

# Comment!: all_ids appends an empty string when no IDs are found,
# it gives a wrong value of 1 when the empty string passes through sort | uniq | wc -l, to solve that this was made:
# Total unique IDs
if [[ -n "$all_ids" ]]; then
    total_unique_ids=$(echo "$all_ids" | sort | uniq | wc -l)
else
    total_unique_ids=0
fi

echo "=== Process summary ==="
echo "Total files processed: $total_files"
echo "Total unique fasta IDs: $total_unique_ids"
