//
// Convert given string to slug.
//

const slugify = require('markdown-it-anchor').defaults.slugify
console.log(slugify(process.argv[2]))
