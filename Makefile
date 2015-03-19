POSTS = $(shell find public -name '*.md')
STYLUS = $(shell find stylus -name '*.styl')
VIEWS = $(shell find views -name '*.jade')

all: bin/md bin/title public/css/main.css $(POSTS:.md=.html)

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

bin/%: src/%.js
	bin/babel < $< > $@
	chmod +x $@

%.html: %.md bin/md $(VIEWS)
	bin/md $$(echo $< | grep -o / | sed '1s/./page/;2s/./post/;2q' | tail -1) < $< > $@

new:
	bin/new
