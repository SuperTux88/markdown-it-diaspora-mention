PATH        := ./node_modules/.bin:${PATH}

NPM_PACKAGE := $(shell node -e 'process.stdout.write(require("./package.json").name)')
NPM_VERSION := $(shell node -e 'process.stdout.write(require("./package.json").version)')

TMP_PATH    := /tmp/${NPM_PACKAGE}-$(shell date +%s)

REMOTE_NAME ?= origin
REMOTE_REPO ?= $(shell git config --get remote.${REMOTE_NAME}.url)

CURR_HEAD   := $(firstword $(shell git show-ref --hash HEAD | cut -b -6) master)
GITHUB_PROJ := https://github.com/diaspora/${NPM_PACKAGE}


lint:
	eslint .

test: lint
	mocha -R spec --inline-diffs

coverage:
	rm -rf coverage
	istanbul cover node_modules/.bin/_mocha

test-ci: lint
	istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -R spec && cat ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js && rm -rf ./coverage

browserify:
	rm -rf ./dist
	mkdir dist
	# Browserify
	( printf "/*! ${NPM_PACKAGE} ${NPM_VERSION} ${GITHUB_PROJ} @license MIT */" ; \
		browserify ./ -s markdownitDiasporaMention -t [ babelify --presets [ es2015 ] ] \
		) > dist/markdown-it-diaspora-mention.js
	# Minify
	uglifyjs dist/markdown-it-diaspora-mention.js -b beautify=false,ascii-only=true -c -m \
		--preamble "/*! ${NPM_PACKAGE} ${NPM_VERSION} ${GITHUB_PROJ} @license MIT */" \
		> dist/markdown-it-diaspora-mention.min.js

release: coverage browserify

.PHONY: lint test coverage
.SILENT: lint test
