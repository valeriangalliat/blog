/* eslint-env browser */

function el (name, attrs = {}, children = []) {
  const element = document.createElement(name)

  for (const [key, value] of Object.entries(attrs)) {
    element[key] = value
  }

  for (const child of children) {
    element.appendChild(child)
  }

  return element
}

function emptyFormData (form) {
  form.querySelector('.posts').textContent = ''
  form.querySelector('.message').textContent = ''
}

function formMessage (form, textContent) {
  emptyFormData(form)
  form.querySelector('.message').appendChild(el('p', { textContent }))
}

async function searchBlog (form) {
  const query = form.query.value.trim().toLowerCase()

  if (!query.length) {
    return
  }

  const q = `${query} in:file language:markdown repo:valeriangalliat/blog`

  const [result, posts] = await Promise.all([
    fetch(`https://api.github.com/search/code?q=${encodeURIComponent(q)}`)
      .then(res => res.json()),
    fetch('/posts.html')
      .then(res => res.text())
  ])

  const items = result.items.filter(item => !['index.md', 'posts.md', 'README.md'].includes(item.path) && !item.path.startsWith('1337/'))

  if (!items.length) {
    return formMessage(form, 'No matches found on the blog. 🥺')
  }

  const parser = new DOMParser()
  const postsDocument = parser.parseFromString(posts, 'text/html')

  const lis = (await Promise.all(items.map(async item => {
    const relativeUrl = item.path.replace(/\.md$/, '.html')
    const url = `/${relativeUrl}`
    const a = postsDocument.querySelector(`a[href="${relativeUrl}"]`)

    if (a) {
      const li = a.parentNode
      a.href = url
      const small = li.lastElementChild
      li.customSortValue = small ? Date.parse(small.textContent) : 0
      return li
    }

    // We find blog post titles in `/posts.html` above, but for pages, we need
    // to `fall back to fetching `<h1>` from the actual page.
    const res = await fetch(url)

    if (!res.ok) {
      // Not found?
      return
    }

    const html = await res.text()
    const pageDocument = parser.parseFromString(html, 'text/html')

    return el('li', { customSortValue: 0 }, [
      el('a', {
        href: url,
        textContent: pageDocument.querySelector('h1').textContent
      }),
      el('small', {
        textContent: '—'
      })
    ])
  })))
    // Ignore discarded items.
    .filter(li => li)

  lis.sort((a, b) => b.customSortValue - a.customSortValue)

  const ul = el('ul', {}, lis)

  emptyFormData(form)
  form.querySelector('.posts').appendChild(ul)
}

// eslint-disable-next-line no-unused-vars
function onSearchSubmit (form) {
  searchBlog(form)
    .catch(err => {
      console.error(err)
      formMessage(form, 'An error occurred! Check the console. 🤭')
    })

  return false
}

for (const button of Array.from(document.querySelectorAll('.change-color-theme'))) {
  if (document.documentElement.classList.contains('dark')) {
    button.textContent = '🌞'
  }

  button.addEventListener('click', () => {
    if (document.documentElement.classList.contains('dark')) {
      document.documentElement.classList.remove('dark')
      document.documentElement.classList.add('light')
      button.textContent = '🌝'
      localStorage.theme = 'light'
    } else {
      document.documentElement.classList.remove('light')
      document.documentElement.classList.add('dark')
      button.textContent = '🌞'
      localStorage.theme = 'dark'
    }
  })
}
