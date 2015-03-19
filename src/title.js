//
// Find the title from input Markdown file and output it as a slug.
//

import assert from 'assert'
import concat from 'stream-concat-promise'
import md from 'markdown-it'

// Do not fail on pipe break.
process.stdout.on('error', err => {
  if (err.code === 'EPIPE') {
    process.exit(0)
  }
})

const parser = md({
  html: true,
  typographer: true,
})

parser.use(require('markdown-it-title'))

const slugify = require('markdown-it-anchor').defaults.slugify
const env = {}

concat(process.stdin, { encoding: 'string' })
  .then(src => parser.render(src, env))
  .then(() => assert(env.title, 'Title not found.'))
  .then(() => env.title)
  .then(title => {
    console.log(title)
    console.log(slugify(title))
  }, err => {
    console.error(err.message)
    process.exit(1)
  })
