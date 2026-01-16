#!/bin/bash
# Script to generate Terraform module documentation for Sphinx
# This script generates Markdown files from terraform-docs that can be included in RST files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$DOCS_DIR")"
TEMP_DIR="${DOCS_DIR}/_generated"

# Create temporary directory for generated docs
mkdir -p "$TEMP_DIR"

# Function to generate documentation for a module
generate_module_docs() {
    local module_dir="$1"
    local module_name="$2"
    
    if [ ! -d "$module_dir" ]; then
        echo "Warning: Module directory $module_dir does not exist"
        return
    fi
    
    echo "Generating documentation for $module_name module..."
    
    # Generate full documentation with terraform-docs
    terraform-docs markdown table \
        --output-file "${TEMP_DIR}/${module_name}_full.md" \
        --config "${ROOT_DIR}/.terraform-docs.yml" \
        "$module_dir" || {
        echo "Error: Failed to generate docs for $module_name"
        return 1
    }
    
    # Extract Inputs and Outputs sections using Python
    python3 << EOF
import re
import sys

try:
    with open("${TEMP_DIR}/${module_name}_full.md", "r") as f:
        content = f.read()
    
    # Extract Inputs section (using # Inputs as header) - without the header itself
    inputs_match = re.search(r'# Inputs\s*\n\n(.*?)(?=\n# |<!-- END_TF_DOCS -->|$)', content, re.DOTALL)
    if inputs_match:
        with open("${TEMP_DIR}/${module_name}_inputs.md", "w") as f:
            # Write content without the header - it will be added in the module RST file
            f.write(inputs_match.group(1).strip())
            f.write("\n")
    else:
        print(f"Warning: Could not extract Inputs section for $module_name", file=sys.stderr)
        # Create empty file to avoid errors
        with open("${TEMP_DIR}/${module_name}_inputs.md", "w") as f:
            f.write("*No inputs documented.*\n")
    
    # Extract Outputs section (using # Outputs as header) - without the header itself
    outputs_match = re.search(r'# Outputs\s*\n\n(.*?)(?=\n# |<!-- END_TF_DOCS -->|$)', content, re.DOTALL)
    if outputs_match:
        with open("${TEMP_DIR}/${module_name}_outputs.md", "w") as f:
            # Write content without the header - it will be added in the module RST file
            f.write(outputs_match.group(1).strip())
            f.write("\n")
    else:
        print(f"Warning: Could not extract Outputs section for $module_name", file=sys.stderr)
        # Create empty file to avoid errors
        with open("${TEMP_DIR}/${module_name}_outputs.md", "w") as f:
            f.write("*No outputs documented.*\n")
    
except Exception as e:
    print(f"Error processing $module_name: {e}", file=sys.stderr)
    sys.exit(1)
EOF
    
    # Convert to RST format for Sphinx
    if [ -f "${SCRIPT_DIR}/markdown_to_rst.py" ]; then
        python3 "${SCRIPT_DIR}/markdown_to_rst.py" "${TEMP_DIR}/${module_name}_inputs.md" "${TEMP_DIR}/${module_name}_inputs.rst" || true
        python3 "${SCRIPT_DIR}/markdown_to_rst.py" "${TEMP_DIR}/${module_name}_outputs.md" "${TEMP_DIR}/${module_name}_outputs.rst" || true
        # Remove intermediate .md files (keep only .rst for Sphinx)
        rm -f "${TEMP_DIR}/${module_name}_inputs.md" "${TEMP_DIR}/${module_name}_outputs.md"
    else
        echo "Warning: markdown_to_rst.py not found, skipping RST conversion" >&2
    fi
}

# Generate documentation for each module
generate_module_docs "${ROOT_DIR}/dbt" "dbt"
generate_module_docs "${ROOT_DIR}/dbtbuildkit" "dbtbuildkit"

echo ""
echo "✓ Documentation generated in ${TEMP_DIR}/"
echo "Generated files:"
ls -la "$TEMP_DIR"
