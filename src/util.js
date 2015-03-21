export function layout (file) {
  const parts = file.split('/')

  switch (true) {
    case /^\d{4}$/.test(parts[1]): return 'post'
    case parts[1].split('.')[0] === 'index': return 'index'
    default: return 'page'
  }
}

export const base = file =>
  file.split('/').map(() => '..').slice(2).join('/') || '.'
