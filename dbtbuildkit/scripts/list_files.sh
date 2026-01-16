#!/bin/bash
# -*- coding: utf-8 -*-
# Script to list all relevant files for Docker build
# Usage: ./list_files.sh <folder_to_monitor> <output_file>

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Error: Usage: $0 <folder_to_monitor> [output_file]"
    echo "Example: $0 src files_list.txt"
    exit 1
fi

FOLDER="${1}"
OUTPUT_FILE="${2:-files_list.txt}"
EXCLUDE_PATTERNS=(
    ".git"
    ".terraform"
    "node_modules"
    "__pycache__"
    "*.pyc"
    ".DS_Store"
    "*.log"
    "*.tmp"
    ".env"
    "*.swp"
    "*.swo"
    "*~"
    ".vscode"
    ".idea"
    "*.egg-info"
    "dist"
    "build"
    ".pytest_cache"
    "coverage"
    ".coverage"
    "htmlcov"
    ".mypy_cache"
    ".ruff_cache"
)

should_exclude() {
    local file="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]] || [[ "$file" == "$pattern" ]]; then
            return 0
        fi
    done
    return 1
}

if [[ ! -d "$FOLDER" ]]; then
    echo "Error: Directory '$FOLDER' does not exist" >&2
    exit 1
fi

> "$OUTPUT_FILE"

echo "Listing files in: $FOLDER"
echo "Output file: $OUTPUT_FILE"
echo ""

find "$FOLDER" -type f | while read -r file; do
    relative_path="${file#$FOLDER/}"

    if ! should_exclude "$relative_path"; then
        echo "$relative_path" >> "$OUTPUT_FILE"
    fi
done

sort -u "$OUTPUT_FILE" -o "$OUTPUT_FILE"

total_files=$(wc -l < "$OUTPUT_FILE")
echo "Total files listed: $total_files"
echo "Files saved to: $OUTPUT_FILE"
echo ""
echo "First 10 files:"
head -10 "$OUTPUT_FILE"
echo ""
echo "Last 10 files:"
tail -10 "$OUTPUT_FILE"
