#!/bin/sh

elm-package install -y

elm-make --yes --output main.html Main.elm
##node main.js
