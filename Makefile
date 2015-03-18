POSTS = $(shell find public -mindepth 1 -name '*.md')
DEPS = bin/md $(shell find views)
ALL = bin/md bin/title public/css/all.css $(POSTS:.md=.html)

all: $(ALL)

public/css/all.css: node_modules/highlight.js/styles/zenburn.css public/css/main.css
	bin/cleancss $^ > $@

public/index.md: $(patsubst public/index.md,,$(POSTS))
	(echo; bin/posts; echo) | bin/between-tags '<!-- BEGIN LIST -->' '<!-- END LIST -->' $@ > $@.tmp
	mv $@.tmp $@

bin/%: src/%.js
	bin/babel < $< > $@
	chmod +x $@

%.css: %.styl
	bin/stylus < $< > $@

%.html: %.md $(DEPS)
	bin/md $$(echo $< | grep -o / | sed '1s/./page/;2s/./post/;2q' | tail -1) < $< > $@

new:
	bin/new
