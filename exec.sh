#!/bin/bash

for file in test_data/hidden/*.lsp; do
  echo $file
  lua scan.lua $file
done
