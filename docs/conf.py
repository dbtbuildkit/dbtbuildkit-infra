# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

from pathlib import Path

# -- Read version from VERSION file -------------------------------------------
# O arquivo VERSION está na raiz do projeto (um nível acima de docs/)
version_file = Path(__file__).parent.parent / 'VERSION'
if version_file.exists():
    with open(version_file, 'r') as f:
        release = f.read().strip()
    # version é apenas MAJOR.MINOR (sem PATCH)
    version = '.'.join(release.split('.')[:2])
else:
    # Fallback caso o arquivo não exista
    release = '0.0.0'
    version = '0.0'

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'DbtBuildKit'
copyright = '2024, DbtBuildKit Team'
author = 'DbtBuildKit Team'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'myst_parser',
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx_immaterial',
]

# templates_path = ['_templates']  # Desabilitado para usar tema conestack sem interferências
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', '_templates', '_generated/*.md', '_generated/*_full.md']

language = 'en'

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_immaterial'
html_static_path = ['_static']
if Path(__file__).parent.joinpath('img').exists():
    html_static_path.append('img')
html_logo = '_static/logo.png'

html_theme_options = {
    "palette": [
        {
            "scheme": "slate",
            "primary": "gray",
            "accent": "orange",
            "toggle": {
                "icon": "material/brightness-7",
                "name": "Switch to light mode",
            },
        },
        {
            "scheme": "default",
            "primary": "gray",
            "accent": "orange",
            "toggle": {
                "icon": "material/brightness-2",
                "name": "Switch to dark mode",
            },
        },
    ],
    "repo_url": "https://github.com/dbtbuildkit/dbtbuildkit-infra",
    "repo_name": "dbtbuildkit/dbtbuildkit-infra",
}
