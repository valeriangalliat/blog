BIN = node_modules/.bin

all: css/main.css

.SUFFIXES: .md .html

.md.html:
	bin/md < $< > $@

CSS = node_modules/highlight.js/styles/zenburn.css css/main.css

css/main.css: css/main.styl
	$(BIN)/stylus < css/main.styl > $@

css/all.css: $(CSS)
	$(BIN)/cleancss $(CSS) > $@
