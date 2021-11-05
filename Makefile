# Example from
# https://tech.davis-hansson.com/p/make/
# Also consider reference at: http://www.gnu.org/software/make/manual/

## Initial setup
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eux -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

## ------------------------- Main part of the build file
AppName := alt-tab-macos

# Default - top level rule is what gets ran when you run just `make`
build:
> xcodebuild -scheme Debug -target ${AppName} -configuration Debug -destination arch=arm64
.PHONY: build

release: dist/${AppName}.app
.PHONY: release

install: dist/${AppName}.app
> [ -e "/Applications/${AppName}.app" ] && rmtrash /Applications/${AppName}.app
> cp -a dist/${AppName}.app /Applications/${AppName}.app
.PHONY: install

dmg: dist/${AppName}.dmg
.PHONY: dmg

## ------------------------- helper

dist:
> mkdir -p dist

artifacts:
> mkdir -p artifacts

artifacts/${AppName}.xcarchive: artifacts $(shell rg --files ${AppName} | sed 's: :\\ :g')
> xcodebuild archive -archivePath $@ -scheme Release -target ${AppName} -configuration Release -destination arch=arm64

dist/${AppName}.app: dist artifacts/${AppName}.xcarchive ExportOptions.plist
> xcodebuild -exportArchive -archivePath './artifacts/${AppName}.xcarchive' -exportOptionsPlist ExportOptions.plist -exportPath dist/ -destination arch=arm64
> touch $@

dist/${AppName}.dmg: dist/${AppName}.app
> create-dmg \
>   --volname "${AppName} Installer" \
>   --window-pos 200 120 \
>   --window-size 500 400 \
>   --icon-size 100 \
>   --icon "${AppName}.app" 100 100 \
>   --hide-extension "${AppName}.app" \
>   --app-drop-link 300 100 \
>   "$@" \
>   "dist/"
