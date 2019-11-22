#!/usr/bin/env bash
# WIP
if [[ ! -d "__tmprepo__/.git" ]]; then
    git clone --bare https://github.com/ybkimm/ybkimm.github.io.git __tmprepo__/.git
fi

