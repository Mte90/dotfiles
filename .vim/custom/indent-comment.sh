#!/usr/bin/env bash

# PHPCBF don't replace `    *` with tabs and keep with space

sed -i 's/     \*/\t \*/g' $@
