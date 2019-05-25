MD = $(shell find public -name '*.md')
HTML = $(MD:public/%.md=dist/%.html)
ASSETS = dist/css/normalize.css dist/css/zenburn.css dist/css/main.css

build: dist $(HTML) $(ASSETS)

dist:
	git clone --branch gh-pages $$(git remote get-url origin) dist

clean:
	rm -f $(HTML)

dist/index.html: public/index.md head.html foot.html
	./render $< | sed '/<header/,/<\/header>/d' > $@

dist/%.html: public/%.md head.html foot.html
	mkdir -p $$(dirname $@)
	./render $< > $@

dist/css/normalize.css: node_modules/normalize.css/normalize.css
	cp $< $@

dist/css/zenburn.css: node_modules/highlight.js/styles/zenburn.css
	cp $< $@

dist/css/main.css: \
	css/base.css \
	css/components/anchor.css \
	css/components/figure.css \
	css/components/footer.css \
	css/components/footnotes.css \
	css/components/title.css \
	css/pages/index.css \
	css/pages/post.css
	cat $^ > $@
