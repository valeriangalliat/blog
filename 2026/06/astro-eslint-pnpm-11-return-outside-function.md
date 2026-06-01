# Astro ESLint with pnpm 11: `return` outside of function
June 1, 2026

After upgrading to pnpm 11, ESLint started flagging every `.astro` page
that returns early from the frontmatter:

```
src/pages/login.astro
  9:3  error  Parsing error: 'return' outside of function
```

The line points to something like this:

```tsx
---
export const prerender = false

if (Astro.locals.user) {
  return Astro.redirect('/')
}
---

<Login />
```

To lint Astro files I use [eslint-plugin-astro](https://www.npmjs.com/package/eslint-plugin-astro)
with a pretty basic config.

Same error [reported on GitHub](https://github.com/ota-meshi/eslint-plugin-astro/issues/459),
still open at time of writing, no resolution except for disabling the
rule entirely.

## Works from CLI but not from editor

Running ESLint from a pnpm script i.e. `pnpm eslint` actually still
worked. Only inside Cursor with the ESLint extension I had the issue.

Nothing specific to Cursor though, figured out just using the
programmatic API with `new ESLint().lintFiles()` failed with the same
error.

Turns out that pnpm wraps `node_modules/.bin/eslint` and sets
`NODE_PATH` to `node_modules/.pnpm/node_modules`, a flat bucket of
symlinks to everything installed in the project.

Sounds like we have a dependency graph problem. Something is missing an
explicit link and that's why it only works when everything is hoisted.

## pnpm history of hoisting of ESLint

Interestingly, pnpm 10 used to [hoist `*eslint*` by default](https://github.com/pnpm/pnpm/issues/8878#issuecomment-2546442011).

This was because ESLint old config format used to have stuff like
`plugins: ['astro']` that had ESLint itself translate this to
`require('eslint-plugin-astro')`. This notoriously doesn't work with
pnpm style of `node_modules` where packages only see their explicit
dependencies and not everything in the entire project.

Since then, ESLint moved to [flat config](https://eslint.org/docs/latest/use/configure/migration-guide)
that doesn't rely on those implicit dependencies.

Everything in my project uses ESLint flat config so this wasn't the
issue, but this default hoisting of `*eslint*` packages was still
helping me when it comes to my Astro parsing.

## Root cause

`eslint-plugin-astro` probes for `@typescript-eslint/parser` at load
time (optional, not an explicit hard dependency). When it cannot
resolve the package, it falls back to the Espree parser.

Espree seems to treat frontmatter `return` as a module-level return and
errors. `@typescript-eslint/parser` does not.

## RTFM, kinda

Guess what? `eslint-plugin-astro` [documents](https://www.npmjs.com/package/eslint-plugin-astro#user-content--installation):

> If you write TypeScript in Astro components, you also need to install
> the `@typescript-eslint/parser`:
>
> ```sh
> npm install --save-dev @typescript-eslint/parser
> ```

I do use TypeScript, although the above failing example was
JavaScript-only. Docs frame it as a TypeScript dependency, but in
practice `@typescript-eslint/parser` seems to play better with astro
files in general, even JavaScript, at least when early `return` is
involved.

## TLDR

ESLint erroring with `'return' outside of function` on `.astro`
frontmatter after upgrading to pnpm 11.

Fix: `pnpm add -D @typescript-eslint/parser` so `eslint-plugin-astro`
picks it up instead of Espree. Needed for TypeScript, but also helps
with things like early `return` in frontmatter.
