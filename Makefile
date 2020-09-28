MD = $(shell find . -name '*.md' ! -path './node_modules/*' ! -path './drafts/*' ! -path './README.md' | sed 's,^./,,')
HTML = $(MD:%.md=dist/%.html)
ICONS = dist/img/icons/403-instagram.svg dist/img/icons/407-twitter.svg dist/img/icons/414-youtube.svg dist/img/icons/433-github.svg dist/img/icons/452-soundcloud.svg
ASSETS = dist/css/normalize.css dist/css/github.css dist/css/main.css $(ICONS)

build: dist $(HTML) $(ASSETS)

dist:
	git clone --branch gh-pages $$(git remote get-url origin) dist

clean:
	rm -f $(HTML)

dist/index.html: index.md head.html foot.html
	mkdir -p $$(dirname $@)
	./render $< | sed 's/class="page"/class="page index"/' > $@

dist/%.html: %.md head.html foot.html
	mkdir -p $$(dirname $@)
	./render $< > $@

dist/css/normalize.css: node_modules/normalize.css/normalize.css
	cp $< $@

dist/css/github.css: node_modules/highlight.js/styles/github.css
	cp $< $@

dist/css/main.css: \
	css/base.css \
	css/components/anchor.css \
	css/components/figure.css \
	css/components/footer.css \
	css/components/footnotes.css \
	css/components/header.css \
	css/components/nav.css \
	css/components/hero.css \
	css/pages/index.css \
	css/pages/post.css
	cat $^ > $@

dist/img/icons/%.svg: node_modules/icomoon-free-npm/SVG/%.svg
	cat $< | sed 's/<svg /<svg id="icon" /;s/fill="#000000"/style="fill: var(--color-fill)"/' > $@

serve:
	cd dist && python -m http.server
