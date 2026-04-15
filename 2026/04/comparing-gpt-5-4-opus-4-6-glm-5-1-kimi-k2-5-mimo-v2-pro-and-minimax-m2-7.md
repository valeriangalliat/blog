# Comparing GPT-5.4, Opus 4.6, GLM-5.1, Kimi K2.5, MiMo V2 Pro and MiniMax M2.7
April 14, 2026

So listen, I was just trying to eject a drive and I ended up spending
the day benchmarking LLMs.

In a hurry? Jump to the [results](#getting-the-models-to-review-each-other)
or the [conclusion](#a-surprising-finding-on-lack-of-biases). Otherwise make some tea, relax and
read on.

It started with this error:

<figure class="center">
  <img alt="Disk wasn't ejected because one or more programs may be using it" srcset="../../img/2026/04/disk-not-ejected.png 2x">
</figure>

Usually I just `lsof /Volumes/Data` and kill whatever is causing the
issue (99% Spotlight or QuickLook).

But you know what, I'm at the point where I need to renew my AI coding
subscription and after a while on Claude in Cursor and a bit of GPT 5.4
in Codex, I wanted to see what's out there, and especially compare the
big two to the open weights models available through OpenCode Go.

After all, Cursor based their Composer 2 model on Kimi K2.5 so it's
probably decent, and I've heard good things about GLM-5.1.

So I decided to compare those models to build a native macOS app to make
the above experience a bit nicer.

* Show external drives and allow to unmount them.
* When unmounting from the app, show a popup with what's blocking
  and allow to kill the process.
* If unmounting from the normal macOS context menu, the app should also
  detect a disk that failed to unmount, and show our popup.

Simple as that.

When it comes the planning and building experience, I'll document
_vibes_ only, because nothing really stood out here. And this is all
that matters these days anyway doesn't it?

As for code analysis and final ranking, it's a bit more thorough, don't
worry.

## Planning

I ran all models through OpenCode. Started in planning mode, and
answered all questions they asked if any.

They all had a pretty similar plan. Slight variations in irrelevant
details, but everything was reasonable when it comes to the underlying
commands and APIs to built upon.

The only one that stood out was MiMo, kernel API instead of shelling out
to `lsof`. Do what you want with that but I don't really care.

It's a tie for me on this aspect.

## Building

OpenCode lets the model run shell commands so they were all able to
compile the app and iterate on build failures on their own.

This means when the models were done, the code was compiling. It's a tie
again.

## Runtime

Despite compiling successfully, a few of them crashed as soon as I
launched the app.

When you make a web app, most harnesses allow browser use for the LLM to
test its own output _live_. This gives us the same success loop we had
with compile-time errors.

But there's no such thing for native apps yet.

Nothing to blame the actual models on though.

After fixing those, all apps had one of two outcomes:

* Can't find any disk.
* Finds disks but crashes when trying to eject.

For all of them I could just have keep the vibe coding loop until it
works. <small>(I did not, I have some real work to do and as you can notice,
I'm spending way too much time on this already.)</small>

But as far as I'm concerned it's more or less a tie. Maybe they didn't
work for different reasons, but it would take a comparable amount of
effort to fix.

<div class="note">

**Note:** nothing new here. If you can give the LLM a tool to test its
work end to end, you spend less time writing "doesn't work, pls fix".
Too bad it's not a readily available option here.

</div>

## The code

Let's take the hypothesis for a minute that code quality, as subjective
as it is, is still relevant.

**Then, I have a slight preference for the output of GLM-5.1 and
GPT-5.4.**

Both are more lean and easier to reason about than the other ones.

This is usually synonymous with the software being less buggy _now_, as
well as less buggy _in the future_ when we add/change stuff around. And
in my experience this seems to apply to both LLMs and humans.

But I'm sure you can steer all of them to output a clean and
maintainable app by prompting a bit more, that is, if you know how to
code and care about the code at all.

## Getting the models to review each other

That was a fun experiment. I asked the LLMs to review each other's work,
rank it, and score the cleanliness and technical approach.

**I was worried this was gonna be a slop spiral but the results were not
as over the place as I expected. 👀**

**GPT-5.4** and **Opus 4.6**, the two frontier proprietary models,
nearly always came up in the top 3, with an edge for GPT.

**MiMo V2 Pro** also had a tendency to rank quite high, close to the two
leaders, even if the consensus wasn't as striking.

The caveat is that it scored on the low side for cleanliness, despite
standing out for technical approach.

**GLM-5.1** had a pretty consistent 4th place, but it ranked really high
on cleanliness specifically.

This means it's a decent choice is you want relatively clean code out of
the box and don't mind giving it guidance when it comes to technical
approach.

This is actually something that works best for me. I'd rather steer the
technical approach if it means I don't have to refine output quality as
much.

**Kimi K2.5** and **MiniMax M2.7** were consistently at the bottom, and
in that order. Which is pretty consistent with their cost.

Here's the raw data. Row is candidate, column is judge. Cleanliness and
technical approach are rated out of 10.

### Absolute rank

|              | Overall | GPT-5.4 | Opus 4.6 | GLM-5.1 | Kimi K2.5 | MiMo V2 Pro | MiniMax M2.7 |
|--------------|---------|---------|----------|---------|-----------|-------------|--------------|
| GPT-5.4      | 🥇      | 1       | 2        | 2       | 2         | 1           | 2            |
| Opus 4.6     | 🥈      | 3       | 3        | 3       | 1         | 3           | 1            |
| MiMo V2 Pro  | 🥉      | 2       | 1        | 1       | 3         | 4           | 6            |
| GLM-5.1      | 4       | 4       | 4        | 4       | 4         | 2           | 3            |
| Kimi K2.5    | 5       | 5       | 5        | 5       | 5         | 5           | 4            |
| MiniMax M2.7 | 6       | 6       | 6        | 6       | 6         | 6           | 5            |

### Cleanliness

|              | Average | GPT-5.4 | GLM-5.1 | Kimi K2.5 | MiMo V2 Pro | MiniMax M2.7 |
|--------------|---------|---------|---------|-----------|-------------|--------------|
| GPT-5.4      | 8.4     | 8.5     | 8       | 9         | 8.5         | 8            |
| GLM-5.1      | 7.8     | 8       | 8       | 8         | 8           | 7            |
| Opus 4.6     | 7.7     | 6.5     | 6       | 9         | 8           | 9            |
| Kimi K2.5    | 6.5     | 6       | 5       | 7         | 7.5         | 7            |
| MiMo V2 Pro  | 6.3     | 6.5     | 7       | 7         | 7           | 4            |
| MiniMax M2.7 | 5.2     | 4       | 4       | 6         | 7           | 5            |

### Technical approach

|              | Average | GPT-5.4 | GLM-5.1 | Kimi K2.5 | MiMo V2 Pro | MiniMax M2.7 |
|--------------|---------|---------|---------|-----------|-------------|--------------|
| GPT-5.4      | 8.2     | 9       | 8       | 9         | 7           | 8            |
| Opus 4.6     | 7.9     | 8       | 7       | 9         | 7.5         | 8            |
| MiMo V2 Pro  | 7.4     | 8.5     | 9       | 8         | 7.5         | 4            |
| GLM-5.1      | 6.4     | 6       | 5       | 7         | 7           | 7            |
| Kimi K2.5    | 5.6     | 4       | 6       | 7         | 6           | 5            |
| MiniMax M2.7 | 5.2     | 3       | 5       | 7         | 6           | 5            |

## A surprising finding on (lack of) biases

The most impressing thing for me was that models didn't seem to be
biased by their own performance??

All models gave their own output a score that was either very close to,
or lower than their average score. Even when the average score was low.

GPT-5.4 is the only one that ranked itself first, but guess what, the
consensus also agreed on that. 😎


## Conclusion

I'm gonna keep using GLM-5.1 via OpenCode Go for the rest of the month
or until I run out of usage. Then switch to GPT-5.4 via Codex Plus
to see if it's worth the extra $$$, both in terms of quality and
quantity.

Though by then I'll probably have 5 other models to test. 😂🙃

## Meta conclusion

Comparing models is peak procrastination. Any of the top models will do
just fine.

And I guess GLM and MiMo are now playing in that league at a fraction of
the cost.

If you have a clear idea what you want, you'll need to steer all
of them in one way or another. Just pick one and get back to work.
