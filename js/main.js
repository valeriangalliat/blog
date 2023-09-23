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

  const items = await fetch(`/api/search?q=${encodeURIComponent(query)}`)
    .then(res => res.json())

  if (!items.length) {
    return formMessage(form, 'No matches found on the blog. 🥺')
  }

  const lis = items.map(({ title, path, date }) => {
    const url = `/${path}`

    return el('li', {}, [
      el('a', {
        href: url,
        textContent: title
      }),
      el('small', {
        textContent: date || '—'
      })
    ])
  })

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
