# 📖 Blog

> My personal blog.

## Description

This repository contains the scripts to build my static blog, together
with the articles Markdown source.

Everything is built around a [makefile](Makefile). Markdown parsing is
done with the [markdown-it] library and a couple of plugins.

[markdown-it]: https://github.com/markdown-it/markdown-it

Everything in this repository is in the public domain, thanks to the
[Unlicense](http://unlicense.org/), but if you want to hack on this
project, you probably want to remove the content and keep only the
engine.

## Usage

You need Node.js and GNU `make` to build.

```sh
npm install
make -j8
```

This will create a `dist` directory that is setup to track the
`gh-pages` branch of this repository and contains the built site.

## Deploy

After building:

```sh
cd dist
git add .
git commit -m 'Build'
git push
```

## Create a new post

```sh
make new
```

This will prompt you for a title, suggest a slug or let you use a custom
one, and will update `index.md` to add the post to the latest articles
(and remove the oldest one), as well as `posts.md`, and create the post
Markdown file with an empty template.
