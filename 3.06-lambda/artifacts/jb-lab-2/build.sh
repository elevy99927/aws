#!/bin/bash
# Builds function.zip: the handler + Pillow compiled for Lambda (Linux x86_64, Python 3.14).
# Run from this folder: cd 3.06-lambda/artifacts/jb-lab-2 && bash build.sh
set -e
cd "$(dirname "$0")"
rm -rf build function.zip
pip install pillow \
  --platform manylinux2014_x86_64 --implementation cp --python-version 3.14 \
  --only-binary=:all: --target build --quiet
cp lambda_function.py build/
(cd build && zip -qr ../function.zip .)
echo "built function.zip ($(du -h function.zip | cut -f1))"
