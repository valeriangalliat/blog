# Make floats and lists collaborate 🙈
April 11, 2022

Am I the only one struggling to get lists and other styled elements to
render properly next to a float?

At least, it definitely doesn't work well out of the box. Let's start
from a generic browser style sheet context (a HTML file without any CSS
added), or [Normalize.css](https://necolas.github.io/normalize.css/).

## The problem

```html
<div class="square"></div>
<ul>
  <li>Hello</li>
</ul>
```

```css
.square {
    float: left;
    width: 6em;
    height: 6em;
    background: 0366d6;
}
```

<iframe src="/img/2022/04/float-demo/example-0.html" width="100%"></iframe>

This is not great. The left padding of the `<ul>` overlaps with the
square, and so does the bullet point.

The only way I'm aware of to fix this in a normal document flow (e.g.
not doing a very custom thing with Flexbox or grids) is to set
`overflow: hidden` to the `<ul>` (or on a parent block that's also being
pushed by the float):

```css
ul {
    overflow: hidden;
}
```

<iframe src="/img/2022/04/float-demo/example-1.html" width="100%"></iframe>

Better. Let's add a paragraph *before* the square and *after* the `<ul>`
and see what happens.

```html
<p>Paragraph</p>
<div class="square"></div>
<ul><li>Hello</li></ul>
<p>Paragraph</p>
```

<iframe src="/img/2022/04/float-demo/example-2.html" width="100%"></iframe>

So far so good.

## Breaking it again

Now let's assume we have paragraphs *inside* our list items (yes, this
happens). You also get a similar problem with `<blockquote>`s or any
other element where you might want to have a left border and padding,
and that contains paragraphs or anything with a vertical margin.


```html
<p>Paragraph</p>
<div class="square"></div>
<ul><li><p>Hello from a paragraph</p></li></ul>
<p>Paragraph</p>
```

<iframe src="/img/2022/04/float-demo/example-3.html" width="100%"></iframe>

Subtle yet important thing to notice: the vertical margin from the
list paragraph now don't merge with the adjacent margins because of our
`overflow: hidden` hack! So we have double the margin before and after
the list. Not good.

But what is this behavior in the first place? Meet [margin collapsing](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Mastering_margin_collapsing).
This concept is is very well defined by [CSS-Tricks](https://css-tricks.com/what-you-should-know-about-collapsing-margins/):

> Collapsing margins happen when two vertical margins come in contact
> with one another. If one margin is greater than the other, then that
> margin overrides the other, leaving one margin.

So by using `overflow: hidden`, we break margin collapsing.

## Avoiding collapsing altogether

It's quite common to use something like `margin-top: 0` and
`margin-bottom: 1em` on all content elements (or the other way
around) to avoid relying on (and dealing with) margin collapsing.

[I ran a poll on Twitter](https://twitter.com/valeriangalliat/status/1512869222111756292)
that got 74 answers. A majority of y'all use this technique to avoid
margin collapsing!

<table>
  <tr>
    <td><code>p { margin: 1em 0; }</code>
    <td>37.8%</td>
  </tr>
  <tr>
    <td><code>p { margin-bottom: 1em; }</code>
    <td>62.2%</td>
  </tr>
</table>

We can try this and see if it helps with our problem.

```css
p, ul {
    margin-top: 0;
}
```

<iframe src="/img/2022/04/float-demo/example-4.html" width="100%"></iframe>

It's better. We don't have double the spacing anymore above the `<ul>`,
but we still have the problem with the `margin-bottom` of the `<ul>` not
collapsing with its inner paragraph.

What we can do though is to set `overflow: hidden` on a wrapper element
instead of the `<ul>` directly, then this should let the inner paragraph
collapse with it's parent `<ul>`'s `margin-bottom`:

```html
<p>Paragraph</p>
<div class="square"></div>
<div class="float-hack">
  <ul><li><p>Hello from a paragraph</p></li></ul>
</div>
<p>Paragraph</p>
```

```css
.float-hack {
    overflow: hidden;
}
```

<iframe src="/img/2022/04/float-demo/example-5.html" width="100%"></iframe>

Sweet, that works like a charm!

That being said, it works especially well because we decided to kill the
`margin-top` of content elements, but if you want to remove the
`margin-bottom` instead and keep the `margin-top`, it's a different
story:

```css
p, ul {
    margin-bottom: 0;
}
```

<iframe src="/img/2022/04/float-demo/example-6.html" width="100%"></iframe>

So keep that in mind of you want to drop margin collapsing, the margin
you kill has an importance!

## A solution to keep collapsing?

The simplicity of the previous solution pretty much convinced me to use
this pattern on my blog. But for some reason you might want to keep
relying on margin collapsing and still need to fix this spacing issues
with floats. Let's find a way.

Since we need to combat the fact that `overflow: hidden` prevents our
vertical margins from collapsing, an option is to set `margin-top: 0`
**recursively** on all the first children of the `overflow: hidden` element,
and `margin-bottom: 0` on all the last children.

Why *recursively*? Because any element in the tree of direct first
children could set a `margin-top` that we want to cancel (and similarly
for `margin-bottom` and the last children tree).

But [we can't recursively target all the first or last children of an element](https://stackoverflow.com/questions/12477272/select-recursive-last-child-possible)!

So a solution would be to write something like this (relying on the
`float-hack` class we introduced earlier:

```css
.float-hack {
    overflow: hidden;
}

.float-hack > :first-child,
.float-hack > :first-child > :first-child,
.float-hack > :first-child > :first-child > :first-child,
.float-hack > :first-child > :first-child > :first-child > :first-child,
.float-hack > :first-child > :first-child > :first-child > :first-child > :first-child {
    margin-top: 0;
}

.float-hack > :last-child,
.float-hack > :last-child > :last-child,
.float-hack > :last-child > :last-child > :last-child,
.float-hack > :last-child > :last-child > :last-child > :last-child,
.float-hack > :last-child > :last-child > :last-child > :last-child > :last-child {
    margin-bottom: 0;
}
```

This should be good enough for most simple cases. You can even have a
paragraph inside a `<blockquote>`, itself inside a list item!

```html
<div class="float-hack">
  <ul>
    <li>
      <blockquote>
        <p>This is a quote</p>
      </blockquote>
    </li>
  </ul>
</div>
```

Or a nested list, which reach the same level of nesting:

```html
<div class="float-hack">
  <ol>
    <li>
      <ol>
        <li>Nested list item</li>
      </ol>
    </li>
  </ol>
</div>
```

Maybe don't add a `<blockquote>` with paragraphs inside this nested list
item or you might want to add a few recursion levels to our earlier CSS
rule. 😂

<div class="note">

**Note:** this isn't a complete fix as it won't behave properly if the
collapsing margins are not equal.

The engine normally keeps the greater margin, but here we'll always nuke
the margin of the first and last items of our `float-hack` element.

</div>

## Wrapping up

And there you go! Two solutions for the price of one:

1. Prevent margin collapsing altogether by only applying a
   `margin-bottom` and setting `margin-top: 0` on all content elements.
1. Recursively target the first and last children of the `overflow: hidden`
   element to cancel their margin.

Which one is your favorite?
