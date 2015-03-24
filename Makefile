MD = $(shell find public -name '*.md') public/index.md public/posts.md
MD_HTML = $(MD:.md=.html)

JS = $(shell find src -name '*.js')
JS_DIST = $(addprefix dist/,$(notdir $(JS)))

POSTS = $(shell bin/posts)
POSTS_HTML = $(POSTS:.md=.html)

STYLUS = $(shell find stylus -name '*.styl')
VIEWS = $(shell find views -name '*.jade')

LIST = (echo; cat; echo) | bin/between-tags '<!-- BEGIN LIST -->' '<!-- END LIST -->'

.SILENT:

all: $(JS_DIST) public/css/main.css $(MD_HTML) public/feed.xml

public/css/main.css: \
	node_modules/normalize.css/normalize.css \
	node_modules/highlight.js/styles/zenburn.css \
	stylus/main.css
	@echo 'generate $@'
	bin/cleancss $^ > $@

stylus/main.css: $(STYLUS)
	echo 'stylus stylus/main.styl'
	bin/stylus stylus/main.styl

public/index.md: public/index.md.list bin/list $(POSTS_HTML)
	echo 'update $@'
	bin/list index $(POSTS_HTML) | $(LIST) $< > $@

public/posts.md: public/posts.md.list bin/list $(POSTS_HTML)
	echo 'update $@'
	bin/list posts $(POSTS_HTML) | $(LIST) $< > $@

public/feed.xml: public/feed.xml.list bin/list $(POSTS_HTML)
	echo 'update $@'
	bin/list feed $(POSTS_HTML) | $(LIST) $< > $@

dist/%.js: src/%.js
	echo 'babel $<'
	bin/babel < $< > $@

%.html: %.part.html dist/render.js $(VIEWS)
	echo 'render $<'
	bin/render $< | bin/html-minifier -c .html-minifier > $@

.PRECIOUS: %.part.html

%.part.html: %.md dist/md.js
	echo 'md $<'
	bin/md < $< > $@

new:
	bin/new
