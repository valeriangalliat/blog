MD = $(shell find . -name '*.md' ! -path '*/node_modules/*' ! -path './drafts/*' ! -path './README.md' | sed 's,^./,,')
HTML = $(MD:%.md=dist/%.html)
ICONS = dist/img/icons/instagram.svg dist/img/icons/x.svg dist/img/icons/youtube.svg dist/img/icons/github.svg dist/img/icons/kofi.svg dist/img/icons/rss.svg
ASSETS = dist/css/normalize.css dist/css/github-20220617.css dist/css/main-20260125.css dist/js/emojicon.js dist/js/main-20230317.js dist/api/search.js $(ICONS)
FEED = dist/feed.xml

build: dist $(HTML) $(ASSETS)

publish: build
	./scripts/generate-feed > $(FEED)

dist:
	git worktree add dist gh-pages
	rm dist/.git
	# Hack for Vercel CLI requiring `.git`. to be a dir
	ln -s ../.git/worktrees/dist dist/.git

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
	cd dist && python3 -m http.server 8000

# Useful to test the redirects from `dist/vercel.json`,
# but requires logging in to Vercel CLI
serve-vercel:
	cd dist && npx vercel dev -l 8000

dev:
	npx concurrently 'make watch' 'make serve'

dev-vercel:
	npx concurrently 'make watch' 'make serve-vercel'

dist/index.html: index.md head.html foot.html
	mkdir -p $$(dirname $@)
	./scripts/render $< | sed 's/class="page"/class="page index"/' > $@

dist/%.html: %.md head.html foot.html
	mkdir -p $$(dirname $@)
	./scripts/render $< > $@

dist/css/normalize.css: node_modules/normalize.css/normalize.css
	cp $< $@

dist/css/github-20220617.css: node_modules/highlight.js/styles/github.css node_modules/highlight.js/styles/github-dark.css
	./scripts/compile-hljs $^ > $@

dist/css/main-20260125.css: \
	css/colors.css \
	css/base.css \
	css/components/anchor.css \
	css/components/contact.css \
	css/components/figure.css \
	css/components/footer.css \
	css/components/header.css \
	css/components/nav.css \
	css/components/note.css \
	css/components/oversized.css \
	css/components/social.css \
	css/components/details.css \
	css/pages/index.css \
	css/pages/post.css
	cat $^ > $@

dist/js/emojicon.js: node_modules/emojicon-big/index.js node_modules/emojicon-big/auto.js
	cat $^ > $@

dist/js/main-20230317.js: js/main.js
	cp $^ $@

dist/api/%.js: api/%.js
	cp $^ $@

dist/img/val.jpg:
	curl https://photography.codejam.info/photos/full/P2570771.jpg | magick - -resize 1280x -crop '1280x512+0+%[fx:88.5/100*(h-512)]' $@

dist/img/freelance.jpg:
	magick IMG_7587.jpeg -resize 1280x -crop '1280x512+0+%[fx:50/100*(h-512)]' $@

dist/img/icons/%.svg: node_modules/simple-icons/icons/%.svg
	cat $< | sed 's/<svg /<svg id="icon" /' > $@

css/colors.css:
	./scripts/colors > $@
