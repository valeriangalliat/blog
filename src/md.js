//
// Render input Markdown file as HTML.
//
// Layout name is given as first argument.
//

import concat from 'stream-concat-promise'
import fs from 'fs'
import jade from 'jade'
import mdit from 'markdown-it'
import * as util from './util'

const file = process.argv[2]
const layout = util.layout(file)
const base = util.base(file)

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

concat(fs.createReadStream(file), { encoding: 'string' })
  .then(src => md.render(src, env))
  .then(html => render(Object.assign({ base, layout, html }, env)))
  .then(console.log)
  .then(null, require('promise-done'))
