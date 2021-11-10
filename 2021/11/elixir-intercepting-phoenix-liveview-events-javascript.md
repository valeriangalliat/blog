---
tweet: https://twitter.com/valeriangalliat/status/1456786062039261187
---

# Elixir: intercepting Phoenix LiveView events in JavaScript
November 5, 2021

Recently, I was dealing with a Phoenix LiveView where I wanted to
intercept some events from the LiveSocket to take specific action in
JavaScript.

Typically, I wanted to know when a form was done being submitted and
processed by the backend **even if that event didn't trigger a DOM
change**.

## The use case

To give the context, I have a `<span>` that is transformed to a `<form>`
on click. For reactivity, this is done in JavaScript. When the form is
submitted, it triggers a Phoenix event that might or might not update
the DOM.

I don't want to reset the state back to the `<span>` on submission,
because it would temporarily show the old text until the update is
processed by the backend and the DOM is updated, which causes a quick
text flash.

In the happy path where the form submission triggers a DOM update
Phoenix resets the DOM to the `<span>` and everything is good, but
if we just added a bunch of spaces to the existing text and the backend
decides to trim the value, Phoenix is smart enough to notice that since
the input state didn't change, it doesn't need to update the DOM. This
is great, except it leaves us with the open `<form>` even if the
submission was handled successfully.

To deal with this, I wanted a way to tell from JavaScript when the form
submission was *completed* so that I can make sure to reset the `<span>`
only then (to avoid the quick text flash mentioned earlier).

## Using Phoenix LiveView hooks?

The first thing I thought about was to use LiveView hooks as documented
in [JavaScript interoperability](https://hexdocs.pm/phoenix_live_view/js-interop.html).

```js
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')

const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    ElementUpdated: {
      updated (e) {
        this.el.dispatchEvent(new CustomEvent('phx:element-updated'))
      }
    }
  }
})

liveSocket.connect()
```

By adding `phx-hook="ElementUpdated"` on the elements we want to get
notified for updates, we trigger the hook we defined, which here
dispatches a custom `phx:element-updated` on the node. This allows us to
handle that event at the node level instead of trying to handle every
single case directly from the hook, which is very nice and decoupled if
you ask me.

For example you could now do:

```js
someElement.addEventListener('phx:element-updated', () => {
  // Deal with the fact this element got updated!
})
```

Sadly, this didn't work for me because the `updated` hook only fires
when the element is... updated, which is not the case if the form
submission completes but doesn't result in a state change. Bummer.

## Leveraging the `phx:page-loading-stop` `window` event

This is the easiest solution. Unlike the one I talk about after, it
doesn't give any granularity on the kind of event that was sent or
received, but it's very easy to implement.

In my case, I use [Alpine](https://alpinejs.dev/) so my code looks something like this:

```html
<div x-data="{ edit: false }" @click="edit = true" @click.outside="edit = false" @phx:page-loading-stop.window="edit = false">
  <span x-show="!edit"><!-- ... --></span>
  <form x-show="edit" phx-submit="edit_whatever"><!-- ... --></form>
  <!-- ... -->
</div>
```

We start with a state of `edit: false`. When that element is clicked, we
switch the `<span>` to a `<form>` to let the user edit it. On
submission, if the DOM is refreshed, Phoenix will reset the state
anyways and we're back to the `<span>`, but if it's not (e.g. input not
modified), we can still handle the `page-loading-stop` event to go back
to `<span>` mode. Sweet!

<div class="note">

**Note:** if you don't use Alpine, you can just listen to the
`phx:page-loading-stop` event on the `window` object:

```js
addEventListener('phx:page-loading-stop', () => {
  // Your code here!
})
```

</div>

## Monkey patching the LiveSocket 🙈

Oh yeah, we love monkey patching. If you use Phoenix LiveView your code
should look something like this (I left alone the Alpine part because
it's not relevant to this example).

```js
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')

const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken }
})

liveSocket.connect()
```

From there, we can intercept the `push` method on the LiveSocket
channel. That will in turn allow us to add an event handler to the
`receive` event for a given push, so that we can not only get the full
response from Phoenix, but can also tell from what event it originated!

```js
const channel = Object.values(liveSocket.roots)[0].channel
const pushImpl = channel.push

channel.push = function wrappedPush (event, payload, timeout) {
  const push = pushImpl.call(this, event, payload, timeout)

  push.receive('ok', resp => {
    console.log(event, payload, resp)
  })

  return push
}
```

In the case of my `<form>` example earlier, `event` is set to the string
`event`, `resp` would contain a `diff` object that really only makes
sense to Phoenix (or be an empty object if nothing was updated), and the
`payload` would look something like this:

```json
{
  "type": "form",
  "event": "edit_whatever",
  "value": "URL encoded string of the form elements"
}
```

This gives pretty useful informations that can allow to hook to LiveView
events in a much more granular manner!

While I didn't end up needing that method, I found this trick during my
numerous attempts at dealing with that issue and I found it would be
pretty useful to documented as it's pretty easy to implement and I
didn't find anything similar online.

## Further reading

If you enjoy reading about this topic, I encourage you to read those two
articles I stumbled upon during my research on this subject.

* [Integrating Phoenix LiveView with JavaScript and AlpineJS](http://blog.pthompson.org/alpine-js-and-liveview)
  by [Patrick Thompson](http://blog.pthompson.org/), for a cool demo of
  using hooks and events to make LiveView and Alpine play nice together
  (but sadly not nice enough for my edge case).
* [Using channels with LiveView for better UX](https://elixirschool.com/blog/live-view-with-channels/)
  by [Sophie DeBenedetto](https://twitter.com/sm_debenedetto), to extend
  the LiveSocket with a custom channel that allow passing granular
  messages to the client. It's pretty complex and it kinda scared me at
  first to be honest, but if my [monkey patch](monkey-patching-the-livesocket)
  solution wasn't flexible enough for you, this one surely will!
