MD = $(shell find . -name '*.md' ! -path '*/node_modules/*' ! -path './drafts/*' ! -path './README.md' | sed 's,^./,,')
HTML = $(MD:%.md=dist/%.html)
ICONS = dist/img/icons/403-instagram.svg dist/img/icons/407-twitter.svg dist/img/icons/414-youtube.svg dist/img/icons/433-github.svg dist/img/icons/452-soundcloud.svg dist/img/icons/219-heart.svg dist/img/icons/412-rss.svg
ASSETS = dist/css/normalize.css dist/css/github-20220617.css dist/css/main-20230317.css dist/js/emojicon.js dist/js/main-20230317.js dist/api/search.js $(ICONS)
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
	cd dist && npx vercel dev -l 8000

dev:
	make watch & make serve

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

dist/css/main-20230317.css: \
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

dist/img/icons/%.svg: node_modules/icomoon-free-npm/SVG/%.svg
	cat $< | sed 's/<svg /<svg id="icon" /;s/ fill="#000000"//' > $@

dist/img/icons/instagram.png:
	curl 'https://www.instagram.com/static/images/ico/favicon-192.png/68d99ba29cc8.png' | convert - -resize 16x $@

dist/img/icons/twitter.png:
	curl 'https://abs.twimg.com/responsive-web/client-web/icon-ios.b1fc7275.png' | convert - -resize 16x $@

dist/img/icons/gmail.png:
	curl 'https://ssl.gstatic.com/ui/v1/icons/mail/rfr/gmail.ico' | convert 'ico:-[3]' -resize 16x $@

dist/img/icons/linkedin.png:
	curl 'https://static-exp1.licdn.com/sc/h/eahiplrwoq61f4uan012ia17i' | convert - -resize 16x $@

dist/img/icons/ko-fi.png:
	curl 'https://ko-fi.com/favicon.png' | convert - -resize 16x $@

css/colors.css:
	./scripts/colors > $@
