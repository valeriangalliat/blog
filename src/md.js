const es = require('event-stream')
const mdit = require('markdown-it')

const mkMd = (conf, exts=[]) => {
  const instance = mdit(conf)
  exts.forEach(e => instance.use(e))
  return html => instance.render(html)
}

const stream = md =>
  es.wait().pipe(es.mapSync(html => md(html)))

module.exports = (...args) => mkMd(...args)
module.exports.stream = stream
