---
tweet: https://x.com/valeriangalliat/status/1486539328373374977
---

# A second `.gitignore` that ignores itself 🤯
January 26, 2022

When collaborating on a project, it's quite frequent that I create extra
scratch files to fiddle locally. This is your ad hoc `test.js` and alike.

I usually don't want to commit those files, and I don't necessarily want
to add them to the project's `.gitignore` either, because they're only
a product of my local workflow and that shouldn't leak in the shared
repository. What I wanted was like **a second `.gitignore` file**, but
that wouldn't be committed to the repository, essentially *ignoring
itself* (and my scratch files).

For a long time I've just let those files unstaged, carefully avoiding
them every time I make a commit (never using `git add .` and such). But
there is actually a better way.

## All the ways to ignore files in Git

As mentioned in the [`.gitignore` man page](https://git-scm.com/docs/gitignore),
there's actually multiple layers for Git to ignore files in a repository:

* Patterns passed as command line arguments.
* Patterns from the `.gitignore` file (most common way).
* Patterns from `.git/info/exclude`.
* Patterns from the file configured in `core.excludesFile`, and
  defaulting to `~/.config/git/ignore`.

## Introducing `.git/info/exclude`

I didn't know it existed, but it was there that whole time! Every Git
repo have an empty `.git/info/exclude` file, which works exactly like a
`.gitignore` file, except it's not committed, and it's only local to
the current copy of the repository.

That's exactly what I wanted! I can add my scratch files to it and I
don't have to worry about accidentally committing them anymore, and I
can finally `git add .` again!

## The original trick with `core.excludesFiles`

The fun thing is that I only learnt about `.git/info/exclude` while
writing this article, I actually didn't go that far in my prior
research. I first discovered the `core.excludesFile` option, which
allowed me to solved my problem, so I stopped at that. It's only when I
started to write about it that I noticed there was an even better
option. This is yet another example of the power of writing, and the
reason why I like to share every little bit of knowledge like this.

Anyways, my original trick was to use the `core.excludesFile` option. As
we saw, we can configure it to an additional `.gitignore` file that can
live anywhere on the system. If set in the global Git config
(`git config --global core.excludesFile`, targeting `~/.gitconfig`),
it'll affect every repository, but if set in the local Git config (`git
config core.excludesFile`, targeting `.git/config`) in a specific repo,
we can add a second `.gitignore` file only for that repo!

So what I did was:

```sh
git config core.excludesFile .valignore
```

And I added a new file, `.valignore`, with the following content:

```gitignore
/.valignore
/test.js
```

Effectively ignoring itself, as well as my scratch file!

The downside is there can only be a single `core.excludesFile`, meaning
this is potentially shadowing a global `core.excludesFile`. If you rely
on that, e.g. you use `~/.config/git/ignore`, you would have to
duplicate its content in the `.valignore` or whatever you called it.

But as I mentioned earlier, `.git/info/exclude` is an even better
solution for this problem, so you can actually have it all!

Happy hacking, and keep learning! 😜
