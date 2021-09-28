MD = $(shell find . -name '*.md' ! -path './node_modules/*' ! -path './drafts/*' ! -path './README.md' | sed 's,^./,,')
HTML = $(MD:%.md=dist/%.html)
ICONS = dist/img/icons/403-instagram.svg dist/img/icons/407-twitter.svg dist/img/icons/414-youtube.svg dist/img/icons/433-github.svg dist/img/icons/452-soundcloud.svg dist/img/icons/458-linkedin.svg dist/img/icons/412-rss.svg
ASSETS = dist/css/normalize.css dist/css/github.css dist/css/main-20210924.css dist/js/emojicon.js dist/js/main-20210719.js $(ICONS)
FEED = dist/feed.xml

build: dist $(HTML) $(ASSETS)

publish: dist $(HTML) $(ASSETS) $(FEED)

dist:
	git worktree add dist gh-pages

pull:
	git -C dist pull && git pull

clean:
	rm -f $(HTML) $(ASSETS)

clean-html:
	rm -f $(HTML)

new:
	./scripts/new

rotate-css:
	./scripts/rotate css

rotate-js:
	./scripts/rotate js

lint:
	./scripts/lint

lint-js:
	npm run lint

watch:
	npm run watch

serve:
	cd dist && python3 -m http.server

dev:
	make watch & make serve

dist/index.html: index.md head.html foot.html
	mkdir -p $$(dirname $@)
	./scripts/render $< | sed 's/class="page"/class="page index"/' > $@

dist/%.html: %.md head.html foot.html
	mkdir -p $$(dirname $@)
	./scripts/render $< > $@

dist/feed.xml: feed.xml dist/posts.html
	./scripts/generate-feed > $@

dist/css/normalize.css: node_modules/normalize.css/normalize.css
	cp $< $@

dist/css/github.css: node_modules/highlight.js/styles/github.css
	cp $< $@

dist/css/main-20210924.css: \
	css/colors.css \
	css/base.css \
	css/components/anchor.css \
	css/components/figure.css \
	css/components/footer.css \
	css/components/footnotes.css \
	css/components/header.css \
	css/components/hero.css \
	css/components/nav.css \
	css/components/note.css \
	css/components/oversized.css \
	css/pages/index.css \
	css/pages/post.css
	cat $^ > $@

dist/js/emojicon.js: node_modules/emojicon-big/index.js node_modules/emojicon-big/auto.js
	cat $^ > $@

dist/js/main-20210719.js: js/main.js
	cp $^ $@

dist/img/icons/%.svg: node_modules/icomoon-free-npm/SVG/%.svg
	cat $< | sed 's/<svg /<svg id="icon" /;s/fill="#000000"/style="fill: var(--color-fill)"/' > $@

css/colors.css:
	echo ':root {' > $@
	curl -s 'https://raw.githubusercontent.com/cdnjs/cdnjs/master/ajax/libs/Primer/17.4.0/base.css' \
		| grep -o '@media (prefers-color-scheme: light){[^}]*}}' \
		| head -1 \
		| npx prettier --stdin-filepath base.css \
		| grep color-scale | sed 's/.*color-scale-/    --/' \
		>> $@
	echo '}' >> $@
