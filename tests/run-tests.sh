#!/bin/sh

##elm-package install -y
elm-make --warn --yes --output test.js Test.elm
##node test.js
