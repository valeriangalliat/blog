PATH := bin:dist:node_modules/.bin:$(PATH)

MD = $(shell find public -type f -name '*.md') public/index.md public/posts.md
MD_HTML = $(MD:.md=.html)

POSTS = $(shell find public -mindepth 2 -type f -name '*.md' | egrep '^public/[0-9]{4}/')
POSTS_HTML = $(POSTS:.md=.html)

JS = $(shell find src -type f)
JS_DIST = $(addprefix dist/,$(notdir $(JS)))

STYLUS = $(shell find stylus -type f -name '*.styl')
VIEWS = $(shell find views -type f -name '*.jade')

LIST = (echo; cat; echo) | between-tags '<!-- BEGIN LIST -->' '<!-- END LIST -->'

.SILENT:

all: $(JS_DIST) public/css/main.css $(MD_HTML) public/feed.xml

public/css/main.css: \
	node_modules/normalize.css/normalize.css \
	node_modules/highlight.js/styles/zenburn.css \
	stylus/main.css
	@echo generate $@
	cleancss $^ > $@

stylus/main.css: $(STYLUS)
	echo stylus stylus/main.styl
	stylus stylus/main.styl

public/index.md: public/index.md.list bin/list $(POSTS_HTML)
	echo update $@
	list index $(POSTS_HTML) | $(LIST) $< > $@

public/posts.md: public/posts.md.list bin/list $(POSTS_HTML)
	echo update $@
	list posts $(POSTS_HTML) | $(LIST) $< > $@

public/feed.xml: public/feed.xml.list bin/list $(POSTS_HTML)
	echo update $@
	list feed $(POSTS_HTML) | $(LIST) $< > $@

dist/%.js: src/%.js
	echo babel $<
	babel < $< > $@

dist/%: src/%
	echo babel $<
	babel < $< > $@
	chmod +x $@

%.html: %.part.html dist/render $(VIEWS)
	echo render $<
	render $< | html-minifier -c .html-minifier > $@

.PRECIOUS: %.part.html

%.part.html: %.md dist/md
	echo 'md $<'
	md < $< > $@

new:
	new
