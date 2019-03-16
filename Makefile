MD = $(shell find public -name '*.md')
HTML = $(MD:%.md=%.html)
ASSETS = public/css/normalize.css public/css/zenburn.css public/css/main.css

build: $(HTML) $(ASSETS)

clean:
	rm -f $(HTML)

public/index.html: public/index.md head.html foot.html
	./render $< | sed '/<header/,/<\/header>/d' > $@

%.html: %.md head.html foot.html
	./render $< > $@

public/css/normalize.css: node_modules/normalize.css/normalize.css
	cp $< $@

public/css/zenburn.css: node_modules/highlight.js/styles/zenburn.css
	cp $< $@

public/css/main.css: \
	css/base.css \
	css/components/anchor.css \
	css/components/figure.css \
	css/components/footer.css \
	css/components/footnotes.css \
	css/components/title.css \
	css/pages/index.css \
	css/pages/post.css
	cat $^ > $@
