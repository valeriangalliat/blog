//
// Clean given Markdown line (parse and remove markup).
//

import mdit from 'markdown-it'

const md = mdit({
  html: true,
  typographer: true,
})

md.use(require('markdown-it-title'))

const env = {}

md.render(`# ${process.argv[2]}`, env)
console.log(env.title)
