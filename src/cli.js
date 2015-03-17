import concat from 'stream-concat-promise'
import jade from 'jade'
import md from 'markdown-it'

const render = locals =>
  jade.renderFile(__dirname + '/../views/post.jade', locals)

const parser = md({
  html: true,
  typographer: true,
})

parser.use(require('markdown-it-anchor'), {
  level: 2, // Do not permalink `<h1>`.
  permalink: true,
  permalinkSymbol: '¶',
})

parser.use(require('markdown-it-deflist'))
parser.use(require('markdown-it-highlightjs'))
parser.use(require('markdown-it-title'))

const env = {}

concat(process.stdin.setEncoding('utf8'))
  .then(src => parser.render(src, env))
  .then(html => render(Object.assign({ html }, env)))
  .then(console.log)
  .then(null, require('promise-done'))
