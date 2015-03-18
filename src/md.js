#!/usr/bin/env node

//
// Render input Markdown file as HTML.
//
// Layout name is given as first argument.
//

import concat from 'stream-concat-promise'
import jade from 'jade'
import mdit from 'markdown-it'

const layout = process.argv[2]

const render = locals =>
  jade.renderFile(__dirname + `/../views/${layout}.jade`, locals)

const md = mdit({
  html: true,
  typographer: true,
})

md.use(require('markdown-it-anchor'), {
  level: 2, // Do not permalink `<h1>`.
  permalink: true,
})

md.use(require('markdown-it-deflist'))
md.use(require('markdown-it-highlightjs'))
md.use(require('markdown-it-title'))

const env = {}

concat(process.stdin, { encoding: 'string' })
  .then(src => md.render(src, env))
  .then(html => render(Object.assign({ html }, env)))
  .then(console.log)
  .then(null, require('promise-done'))
