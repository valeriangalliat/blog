/* global HTMLRewriter */

const github = 'https://raw.githubusercontent.com/valeriangalliat/blog/gh-pages/'

async function titleFromHtml (html) {
  let title = ''
  await new HTMLRewriter().on('h1', {
    text (text) {
      title += text.text
    }
  }).transform(new Response(html)).text()
  return title.trim()
}

async function postMetadata (html) {
  const posts = new Map()
  let entry
  let inAnchor = false
  let inDate = false
  await new HTMLRewriter()
    .on('li', {
      element (element) {
        entry = { title: '', date: '' }
        element.onEndTag(() => {
          if (entry && entry.path) {
            posts.set(entry.path, entry)
          }
          entry = undefined
        })
      }
    })
    .on('li a', {
      element (element) {
        if (!entry) {
          return
        }
        entry.path = element.getAttribute('href')?.replace(/^\//, '')
        inAnchor = true
        element.onEndTag(() => { inAnchor = false })
      },
      text (text) {
        if (entry && inAnchor) {
          entry.title += text.text
        }
      }
    })
    .on('li small', {
      element (element) {
        inDate = true
        element.onEndTag(() => { inDate = false })
      },
      text (text) {
        if (entry && inDate) {
          entry.date += text.text
        }
      }
    }).transform(new Response(html)).text()
  return posts
}

async function search (request, env) {
  const query = new URL(request.url).searchParams.get('q')?.trim().toLowerCase()
  if (!query) {
    return Response.json([])
  }

  if (!env.GITHUB_TOKEN) {
    return Response.json({ error: 'Search is not configured' }, { status: 503 })
  }

  const q = `${query} in:file language:markdown repo:valeriangalliat/blog`
  const [response, postsResponse] = await Promise.all([
    fetch(`https://api.github.com/search/code?q=${encodeURIComponent(q)}`, {
      headers: {
        Authorization: `Bearer ${env.GITHUB_TOKEN}`,
        'User-Agent': 'codejam-blog',
        Accept: 'application/vnd.github+json'
      }
    }),
    fetch(`${github}posts.html`)
  ])
  if (!response.ok || !postsResponse.ok) {
    return Response.json({ error: 'Search unavailable' }, { status: 502 })
  }

  const [data, posts] = await Promise.all([response.json(), postMetadata(await postsResponse.text())])
  const items = data.items.filter(item => !['index.md', 'posts.md', 'README.md'].includes(item.path) && !item.path.startsWith('1337/'))
  const results = await Promise.all(items.map(async item => {
    const path = item.path.replace(/\.md$/, '.html')
    const post = posts.get(path)
    if (post) {
      return {
        title: post.title.trim(),
        path,
        date: post.date.trim(),
        sortValue: Date.parse(post.date) || 0
      }
    }

    const page = await fetch(`${github}${path}`)
    if (!page.ok) {
      return null
    }

    const title = await titleFromHtml(await page.text())
    return title ? { title, path, sortValue: 0 } : null
  }))
  return Response.json(results
    .filter(Boolean)
    .sort((a, b) => b.sortValue - a.sortValue)
    .map(({ sortValue, ...item }) => item))
}

export default {
  async fetch (request, env) {
    const url = new URL(request.url)
    if (url.pathname === '/') {
      url.pathname = '/index.html'
      return env.ASSETS.fetch(new Request(url, request))
    }
    if (url.pathname === '/api/search') {
      try {
        return await search(request, env)
      } catch (error) {
        console.error('Search failed', error)
        return Response.json({ error: 'Search unavailable' }, { status: 502 })
      }
    }
    return env.ASSETS.fetch(request)
  }
}
