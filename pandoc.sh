#!/usr/bin/env bash

pandoc \
  -s \
  -S \
  --toc \
  --number-sections \
  -H pandoc2.css \
  manual.md \
  -o manual.html \
