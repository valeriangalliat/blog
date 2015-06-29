Git
===

Last time I checked, `git` was *the* most used command in my history.
Git is one of the first software I install on a new machine, with curl
and Vim.

Here's all the stuff I collected about Git, that helped me better
understand it and learn to use it properly.

References
----------

* [Pro Git](https://git-scm.com/book/en/v2)
* [Git Magic](http://www-cs-students.stanford.edu/~blynn/gitmagic/)

Tutorials (beginner)
--------------------

* [First steps (GitHub)](https://try.github.io/)
* [Git for Beginners](http://www.sitepoint.com/git-for-beginners/)
* [Enfin comprendre Git](http://www.miximum.fr/enfin-comprendre-git.html) (really complete introduction, in French)

Tips & tricks
-------------

* [Part 1](http://hugogiraudel.com/2014/03/10/git-tips-and-tricks-part-1/)
* [Part 2](http://hugogiraudel.com/2014/03/17/git-tips-and-tricks-part-2/)
* [Part 3](http://hugogiraudel.com/2014/03/24/git-tips-and-tricks-part-3/)

Deepening
---------

### See how it works in the background

* [A Hacker's Guide to Git](http://wildlyinaccurate.com/a-hackers-guide-to-git)
* [Git from the Bottom Up](http://jwiegley.github.io/git-from-the-bottom-up/)
* [Cheat sheet about Git states](http://codepen.io/HugoGiraudel/full/d7a439ac945a29dcad9f02d831b731e6/)

### Reimplementing Git

* [Introducing Gitlet](http://maryrosecook.com/blog/post/introducing-gitlet)
* [Git in six hundred words](http://maryrosecook.com/blog/post/git-in-six-hundred-words)
* [Gitlet](http://gitlet.maryrosecook.com/docs/gitlet.html)

Workflow & branching
--------------------

* [A successful Git branching model](http://nvie.com/posts/a-successful-git-branching-model/)
* [Comparing Workflows](http://www.atlassian.com/git/tutorials/comparing-workflows/)
* [Using git-flow to automate your git branching workflow](http://jeffkreeftmeijer.com/2010/why-arent-you-using-git-flow/)

Other interesting stuff
-----------------------

* [Debugging in Git with Blame and Bisect](http://www.sitepoint.com/debugging-git-blame-bisect/)
* [30 Git CLI options you should know about](https://medium.com/@porteneuve/30-git-cli-options-you-should-know-about-15423e8771df)
* [Git rebase, le couteau suisse de votre historique](http://www.miximum.fr/git-rebase.html) (French)
* [Abandon your DVCS and Return to Sanity](http://bitquabit.com/post/unorthodocs-abandon-your-dvcs-and-return-to-sanity/) (keep in mind DVCS are not perfect)
* [Getting solid at Git rebase vs. merge](https://medium.com/@porteneuve/getting-solid-at-git-rebase-vs-merge-4fa1a48c53aa) (excellent article, exactly my workflow)
* [How to undo (almost) anything with Git](https://github.com/blog/2019-how-to-undo-almost-anything-with-git)

Commit messages
---------------

* [A Note About Git Commit Messages](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
* [How to Write a Git Commit Message](http://chris.beams.io/posts/git-commit/)

### Personal notes

* Use `'` and not Markdown `` ` `` for consistency with default Git
  messages, like `Merge branch 'foo'`.

* For URLs, according to commit messages in Git itself and the Linux
  kernel, either skip a line and indent the URL with 4 spaces:

  ```
  Some message:

      https://www.codejam.info/

  Another sentence.
  ```

  or use link references like this:

  ```text
  Some message referencing a link [1] in a sentence, and maybe even
  another link [2].

  [1] https://www.codejam.info/
  [2] https://git.codejam.info/
  ```

GitHub
------

* [GitHub Cheat Sheet](https://github.com/tiimgreen/github-cheat-sheet)
  (also see their list of [Git resources](https://github.com/tiimgreen/github-cheat-sheet#git-resources))

Handling patches and pull requests
----------------------------------

* [Care And Operation Of Your Linus Torvalds](https://www.kernel.org/doc/Documentation/SubmittingPatches)
* [Gerrit Code Review - Signed-off-by Lines](http://gerrit.googlecode.com/svn/documentation/2.0/user-signedoffby.html)
* [What is the Sign Off feature in Git for?](https://stackoverflow.com/questions/1962094/what-is-the-sign-off-feature-in-git-for/14044024#14044024)
* ["Merge pull request" Considered Harmful](http://blog.spreedly.com/2014/06/24/merge-pull-request-considered-harmful/)

Especially, the part about "slightly modifying patches" in the first
three links:

> If you are a subsystem or branch maintainer, sometimes you need to
> slightly modify patches you receive in order to merge them, because
> the code is not exactly the same in your tree and the submitters'. If
> you stick strictly to rule *C*, you should ask the submitter to
> rediff, but this is a totally counter-productive waste of time and
> energy. Rule *B* allows you to adjust the code, but then it is very
> impolite to change one submitter's code and make him endorse your
> bugs. To solve this problem, it is recommended that you add a line
> between the last `Signed-off-by` header and yours, indicating the
> nature of your changes. While there is nothing mandatory about this,
> it seems like prepending the description with your mail and/or name,
> all enclosed in square brackets, is noticeable enough to make it
> obvious that you are responsible for last-minute changes. Example:
>
> ```
> Signed-off-by: Random J Developer <random@developer.example.org>
> [lucky@maintainer.example.org: struct foo moved from foo.c to foo.h]
> Signed-off-by: Lucky K Maintainer <lucky@maintainer.example.org>
> ```
>
> This practice is particularly helpful if you maintain a stable branch
> and want at the same time to credit the author, track changes, merge
> the fix, and protect the submitter from complaints. Note that under no
> circumstances can you change the author's identity (the `From`
> header), as it is the one which appears in the changelog.

So, in summary:

```
Commit summary

Longer description of the commit.

Closes #42.

[email@domain: fix summary]
[email@domain: fix summary that can be longer and span on multple lines
if needed, though it's still not capitalized nor have a period]
```

Clone the Linux kernel Git repository and search for `\[.*@` to see how
it's used.
