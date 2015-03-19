POSTS = $(shell find public -name '*.md')
STYLUS = $(shell find stylus -name '*.styl')
SOURCES = $(shell find src -name '*.js')
VIEWS = $(shell find views -name '*.jade')

all: $(addprefix dist/,$(notdir $(SOURCES))) public/css/main.css $(POSTS:.md=.html)

public/css/main.css: \
	node_modules/normalize.css/normalize.css \
	node_modules/highlight.js/styles/zenburn.css \
	stylus/main.css
	bin/cleancss $^ > $@

stylus/main.css: $(STYLUS)
	bin/stylus stylus/main.styl

public/index.md: $(patsubst public/index.md,,$(POSTS))
	(echo; bin/posts; echo) | bin/between-tags '<!-- BEGIN LIST -->' '<!-- END LIST -->' $@ > $@.tmp
	mv $@.tmp $@

dist/%.js: src/%.js
	bin/babel $< > $@

%.html: %.md dist/md.js dist/utils.js $(VIEWS)
	bin/md $< > $@

new:
	bin/new
