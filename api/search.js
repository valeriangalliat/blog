import fs from 'node:fs/promises'
import jsdom from 'jsdom'

let postsDocumentCache

export default async function handler (request, response) {
  const url = new URL(request.url, `http://${request.headers.host}`)

  if (!url.searchParams.has('q')) {
    return response.status(200).json([])
  }

  const query = url.searchParams.get('q').trim().toLowerCase()

  if (!query.length) {
    return response.status(200).json([])
  }

  const q = `${query} in:file language:markdown repo:valeriangalliat/blog`

  const [result, postsDocument] = await Promise.all([
    fetch(`https://api.github.com/search/code?q=${encodeURIComponent(q)}`, {
      headers: {
        authorization: `Bearer ${process.env.GITHUB_TOKEN}`
      }
    })
      .then(res => res.json()),
    postsDocumentCache || fetch('https://raw.githubusercontent.com/valeriangalliat/blog/gh-pages/posts.html')
      .then(res => res.text())
      .then(html => new jsdom.JSDOM(html).window.document)
  ])

  const items = result.items.filter(item => !['index.md', 'posts.md', 'README.md'].includes(item.path) && !item.path.startsWith('1337/'))

  if (!items.length) {
    return response.status(200).json([])
  }

  const results = (await Promise.all(items.map(async item => {
    const path = item.path.replace(/\.md$/, '.html')
    const a = postsDocument.querySelector(`a[href="${path}"]`)

    if (a) {
      const li = a.parentNode
      const small = li.lastElementChild

      return {
        title: a.textContent,
        path,
        date: small.textContent,
        sortValue: small ? Date.parse(small.textContent) : 0
      }
    }

    // We find blog post titles in `posts.html` above, but for pages, we need
    // to fall back to fetching `<h1>` from the actual page.
    const html = await fetch(`https://raw.githubusercontent.com/valeriangalliat/blog/gh-pages/${path}`)
      .then(res => res.text())
      .catch(() => null)

    if (!html) {
      return null
    }

    const pageDocument = new jsdom.JSDOM(html).window.document

    return {
      title: pageDocument.querySelector('h1').textContent,
      path,
      sortValue: 0
    }
  })))
    // Ignore discarded items.
    .filter(result => result)
    .sort((a, b) => b.sortValue - a.sortValue)
    .map(result => {
      delete result.sortValue
      return result
    })

  return response.status(200).json(results)
}
