# DbtBuildKit Documentation

This folder contains the Sphinx-generated documentation for the DbtBuildKit Terraform infrastructure.

## Installation

To install required dependencies:

```bash
pip install -r requirements.txt
```

## Building Documentation

To generate HTML documentation:

```bash
make html
```

Documentation will be generated in `_build/html/`.

To view locally:

```bash
cd _build/html && python3 -m http.server 8000
```

Then access `http://localhost:8000` in your browser.

## Structure

- `conf.py`: Sphinx configuration
- `index.rst`: Documentation home page
- `modules/`: Terraform modules documentation
- `variables.rst`: Variables documentation
- `outputs.rst`: Outputs documentation
