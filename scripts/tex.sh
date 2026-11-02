#!/usr/bin/env bash
# Build <dir>/paper.tex to paper.pdf (installs TeX Live on first use). Usage: scripts/tex.sh papers/<slug>
set -euo pipefail
if ! command -v latexmk >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -yqq latexmk texlive-latex-extra texlive-science texlive-fonts-recommended >/dev/null
fi
cd "$1" && latexmk -pdf -interaction=nonstopmode -halt-on-error paper.tex
