const hljs = require('highlight.js')

const maybe = f => (...args) => {
  try { return f(...args) }
  catch (e) { return false }
}

const getter = name => x => x[name]
const then = after => f => (...args) => after(f(...args))
const maybeValue = f => maybe(then(getter('value'))(f))

const hl = (code, lang) => {
  return maybeValue(hljs.highlight)(lang, code, true) ||
    maybeValue(hljs.highlightAuto)(code) ||
    ''
}

module.exports = (...args) => hl(...args)
module.exports.mdConf = { langPrefix: 'hljs language-', highlight: hl }
