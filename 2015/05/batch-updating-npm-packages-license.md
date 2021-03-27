# Batch updating npm packages license
May 25, 2015

Since a few weeks, npm have [deprecated] the old `package.json`
`license` format (where we specify an object with `type` and `url`), and
it now must be just a string.

[deprecated]: https://github.com/npm/npm/commit/8669f7d88c472ccdd60e140106ac43cca636a648

I needed the old format because npm didn't support the [Unlicense] yet,
but it looks like it's not the case anymore!

[Unlicense]: http://unlicense.org/

So I basically have to change the following:

```json
{
  "license": {
    "type": "Unlicense",
    "url": "http://unlicense.org/"
  }
}
```

to this:

```json
{
  "license": "Unlicense"
}
```

for all the packages I have under the Unlicense (roughly 30 packages).

## Automation

I did not want to do this by hand, so I automated this with some
commands. I did not wrote this script at once, but here's what's
resulting of my `history`, with a drastic cleanup (there was *a lot* of
trial and error) and comments:

```sh
# Get all the packages I contribute to
curl -s 'https://www.npmjs.com/~valeriangalliat' | grep /package/ | sed 's,.*/package/,,;s/".*//' > my-packages

# Get the URL of non-deprecated packages
cat my-packages | while read package; do
    node -e "var x = $(npm info "$package");"' if (!x.deprecated) console.log(x.repository.url.replace("git+https", "https"))'
done > repos

# Clone all repositories
cat repos | xargs -L1 git clone

# Get the directory names
cat repos | xargs -L1 basename > dirs

# Update the license
cat dirs | sed 's,$,/package.json,' | xargs sed -i '/license/{N;/Unlicense/{N;N;s/.*/  "license": "Unlicense",/;}}'

# Check the update
cat dirs | xargs -I{} git -C {} diff

# Commit
cat dirs | xargs -I{} git -C {} commit -am 'Update package license format'

# Get the repositories where a change occurred (otherwise the commit was not done)
cat dirs | xargs -I{} sh -c 'cd {} && git log -n 1 | grep -q "Update package license format" && echo {}' > updated

# Bump patch (commit and tag)
cat updated | xargs -I{} npm version patch -m 'Bump %s'

# Check commits to push
cat updated | xargs -I{} git -C {} log origin/master..

# Push, install dependencies and publish
cat updated | xargs -I{} sh -c 'cd {} && git push && npm install && npm publish'
```

## Was it worth it?

In the end, I think it took way more time to write this script (and blog
post) than doing it manually. But it was also *incredibly more fun*!

I hope this may be useful to other people in the same case as me, so it
will be actually productive, in addition to be fun.
