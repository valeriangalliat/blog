# How much is Composer 2.5 subsidized in Cursor?
June 23, 2026

## TLDR

According to my own usage, 10x. If you need more than 10% extra usage
from the Pro plan, don't use on-demand pricing, get a second Pro plan.
If you need more than 10% extra of that second one, get Pro+.

<div class="note">

In this post:

* [What I think of Composer 2.5](#what-i-think-of-composer-2-5)
* [Composer 2.5 vs. Composer 2.5 (Fast) vs. Auto](#composer-2-5-vs-composer-2-5-fast-vs-auto)
* [What happens when you run out of "Auto + Composer" quota?](#what-happens-when-you-run-out-of-auto-composer-quota)
* [How much inference do we get on the $20 Pro plan?](#how-much-inference-do-we-get-on-the-20-pro-plan)
* [Should I enable on-demand usage or upgrade my subscription?](#should-i-enable-on-demand-usage-or-upgrade-my-subscription)
* [Conclusion](#conclusion)


</div>

## Context

I've been using Composer 2.5 in Cursor since it came out on May 18,
2026.

I actually had no clue. I had just ran out of Codex quota and wanted
to try Cursor again to see how much output I can get from the "Auto"
mode in the subscription.

By pure coincidence, the day I want to subscribe, they release Composer
2.5, a significant update to their own model (where "own" means
reinforcement learning fine-tuning of Kimi K2.5).

## What I think of Composer 2.5

I was instantly impressed by the quality to price feel of that model.
It's one of the cheapest models available, yet it seems to rival
GPT-5.5 and Opus 4.8 when it comes to coding? Although it's tricky to
really evaluate that because Composer 2.5 is only available through
Cursor, so it's not possible to rank it on traditional benchmarks like
[Arena AI's Code Arena](https://arena.ai/leaderboard/code).

Instead we have to rely on Cursor's own [CursorBench](https://cursor.com/cursorbench).
To be fair their scoring of other models is not out of ordinary compared
to other coding benchmarks, and the fact the benchmark is private means
that it can't be "gamed" by optimizing for it (except by Cursor
themselves 🙃). So if we can't necessarily trust it for Composer's
performance (it could be trained to perform well on that benchmark
specifically without that translating in real-world performance), it
might actually be a really good benchmark to compare other models.

That being said in day to day use in real projects, not just toy demos
or throwaway stuff, I've been pretty happy. The quality is here and I
get a fuckton more usage than I was getting with Codex for a similar
price.

And that's despite, with Codex, me trying to aggressively limit the
spend by using low thinking most of the time, and older models like
GPT-5.3-Codex. Which also resulted in poorer quality and more
frustration.

In comparison with Composer 2.5, I stick it to the normal mode (not the
"fast" mode they select by default), which is already insanely fast
compared to anything else I'm used to (Codex and OpenCode Go), and I
don't have to think about what model or level of thinking to select for
every prompt, and deal with the resulting variable quality output. I get
consistent quality output and more usage than the competition at the
same price point.

## Composer 2.5 vs. Composer 2.5 (Fast) vs. Auto

Although there's no way to know for sure, it feels like picking "Auto"
in Cursor often results in using Composer 2.5. Unclear whether it's in
fast mode or not though.

When it comes to pricing, here's [what they charge](https://cursor.com/docs/models-and-pricing)
(price per 1M tokens):

| Model               | Input | Cache Read | Output |
|---------------------|------:|-----------:|-------:|
| Composer 2.5        | $0.5  | $0.2       | $2.5   |
| Composer 2.5 (Fast) | $3    | $0.5       | $15    |
| Auto                | $1.25 | $0.25      | $6     |

So Composer 2.5 (Fast) is 6 times more expensive than Composer 2.5 (it's
not clear to me that it's 6 times faster though, as far as I'm concerned
if I'm not in a rush I'm happy with the normal mode).

As for Auto, it's 2.5 times more expensive than Composer 2.5, and it
seems that you get Composer 2.5 at the end anyway. Maybe a bit faster
but no guarantee to be Composer 2.5 (Fast) speed all the time either.

When it comes to the subscription, there's no indication that the usage
you get is proportional to the public pricing of those models. But it
would seem logical to me that using a cheaper option results in less
quota usage than using a more expensive option.

So as far as I'm concerned since I want to maximize my quota usage, I've
been using Composer 2.5 explicitly (not through Auto, and not the fast
mode) most of the time.

## What happens when you run out of "Auto + Composer" quota?

When you max out your "Auto + Composer" quota, if you still have API
quota left, Cursor starts to dip into this for Auto and Composer
requests.

On the $20 plan, Cursor says that the API quota includes "at least $20
of API usage", so you can expect that from this pool once you start
using it. In my experience it's indeed a bit more, see below.

## How much inference do we get on the $20 Pro plan?

Your mileage may vary, but here's what it came out for me after one
month of using (mostly) Composer 2.5.

**Auto + Composer:**

| Model               | Events    | Input      | Cache       | Output    | Total       | API-equiv   |
|---------------------|----------:|-----------:|------------:|----------:|------------:|------------:|
| `auto`              | 211       | 5.73M      | 87.33M      | 905.7K    | 93.96M      | $34.42      |
| `composer-2.5`      | 1,716     | 32.03M     | 495.52M     | 5.35M     | 532.89M     | $128.48     |
| `composer-2.5-fast` | 3         | 34.7K      | 84.4K       | 2.4K      | 121.5K      | $0.18       |
| **Subtotal**        | **1,930** | **37.79M** | **582.93M** | **6.25M** | **626.97M** | **$163.09** |

**API:**

| Model                               | Events  | Input     | Cache       | Output    | Total       | API-equiv  |
|-------------------------------------|--------:|----------:|------------:|----------:|------------:|-----------:|
| `claude-4.6-sonnet-medium-thinking` | 20      | 867.1K    | 9.20M       | 146.8K    | 10.22M      | $8.21      |
| `claude-fable-5-thinking-high`      | 1       | 32.1K     | 0           | 339       | 32.4K       | $0.42      |
| `composer-2.5`                      | 341     | 7.29M     | 140.37M     | 1.16M     | 148.82M     | $34.61     |
| `gpt-5.3-codex`                     | 1       | 43.9K     | 426.1K      | 3.4K      | 473.4K      | $0.20      |
| `gpt-5.5`                           | 11      | 161.4K    | 2.95M       | 8.9K      | 3.12M       | $2.55      |
| **Subtotal**                        | **374** | **8.39M** | **152.95M** | **1.31M** | **162.66M** | **$45.99** |

**Free:**

After I used 100% of my subscription quota, everything kept working and
appeared as "free" in the billing usage log. I'm assuming that's falling
back to their Hobby (free) plan once the subscription is exhausted,
which has much lower limits (although I didn't have time to reach them
this time).

| Model          | Events | Input     | Cache      | Output     | Total      | API-equiv |
|----------------|-------:|----------:|-----------:|-----------:|-----------:|----------:|
| `auto`         | 3      | 41.3K     | 135.4K     | 1.9K       | 178.6K     | $0.10     |
| `composer-2.5` | 76     | 1.49M     | 27.60M     | 198.4K     | 29.29M     | $6.76     |
| **Subtotal**   | **79** | **1.53M** | **27.74M** | **200.3K** | **29.47M** | **$6.86** |

**Grand total:**

| Events    | Input      | Cache       | Output    | Total       | API-equiv   |
|----------:|-----------:|------------:|----------:|------------:|------------:|
| **2,383** | **47.72M** | **763.62M** | **7.77M** | **819.10M** | **$215.94** |

So if my computations are correct, the $20 plan gave me $208 worth of
tokens. $163 of that was in the Auto + Composer pool, and the remaining
$46 was in the API pool. (And $7 Hobby fallback.)

## Should I enable on-demand usage or upgrade my subscription?

Cursor has an option to enable on-demand spending, where usage is billed
at API price after you exhaust your subscription.

When it comes to using Composer 2.5, the subscription gives a 10x boost
in tokens compared to API prices.

The next subscription tier is the $60 Pro+ plan which comes with 3x the
usage, or you can get a second $20 Pro plan (to get obviously 2x the
usage).

This gives us a table like this (based on my own 1 month data, your
mileage may vary):

| Expected usage      | Best choice         |
|--------------------:|---------------------|
| Less than 10% over  | On-demand           |
| More than 10% over  | Second $20 Pro plan |
| More than 210% over | $60 Pro+ plan       |

If you run out of the $20 plan, first you might as well max out the
Hobby (free) quota as well (worth at least $7 apparently).

Then if you need 10% or less extra usage compared to your Pro plan,
on-demand is worth it.

More than that, get a second $20 Pro plan.

If you max out that second plan, the same 10% rule applies for upgrading
to Pro+.

## Conclusion

Composer 2.5 appears to be quite subsidized, where a $20 plan gives over
$200 worth of tokens, about 10 times more than what you pay for.

Though it's not necessarily as subsidized as other subscriptions, as
there's reports of people getting between $2,000 and $8,000 (???) worth
of tokens with the $200 Claude plan.

But because I'm the one paying this subscription and not my employer or
some VC, and because I don't have unlimited money, I find Composer 2.5
is a lot more interesting for my current usage.
