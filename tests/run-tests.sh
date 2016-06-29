#!/bin/sh

elm-package install -y

elm-make --yes --output test.js Test.elm
##node test.js
