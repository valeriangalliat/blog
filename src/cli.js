const mkMd = require('./md')
const hl = require('./hl')

const findTitle = data => md => {
  const originalRule = md.renderer.rules.heading_close

  md.renderer.rules.heading_close = (token, idx, ...args) => {
    if (token[idx].hLevel === 1) {
      data.title = token[idx - 1].children.map(x => x.content).join('')
      md.renderer.rules.heading_close = originalRule
    }

    return originalRule(token, idx, ...args)
  }
}

const conf = { html: true, typographer: true }
const data = {}
const exts = [require('markdown-it-deflist'), findTitle(data)]

const hlConf = Object.assign({}, hl.mdConf, {
  highlight: (...args) => {
    const html = hl(...args)
    data.highlight = html !== ''
    return html
  },
})

const md = mkMd(Object.assign({}, conf, hlConf), exts)

process.stdin.setEncoding('utf8')

process.stdin
  .pipe(mkMd.stream(md))
  .on('end', () => {
    console.log(data)
  })
  .pipe(process.stdout)
