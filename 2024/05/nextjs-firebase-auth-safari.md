# Next.js: make Firebase Auth `signInWithRedirect` work with Safari
May 4, 2024

Had that
[issue](https://github.com/firebase/firebase-js-sdk/issues/6716)
back in 2022 and it's now a pretty
[well-understood](https://firebase.google.com/docs/auth/web/redirect-best-practices)
problem, but better write about it later than never. 😂

Essentially, in Safari 16.1+ (and now Firefox 109+), there are more
aggressive restrictions on third-party cookies that mess with the way
Firebase Auth `signInWithRedirect` is implemented.

By default, your app could be running on `https://myapp.com` but
`signInWithRedirect` would redirect to
`https://myapp.firebaseapp.com/__/auth` and then back to your app in
order to handle the auth. The message passing with third-party cookies
between those two hosts is no longer possible in Safari, Firefox, and
soon Chrome.

Firebase docs now document [5 options](https://firebase.google.com/docs/auth/web/redirect-best-practices)
to solve that.

1. If you host your app on Firebase, make sure your Firebase config
   `authDomain` point to your custom domain and not
   `myapp.firebaseapp.com`. Because Firebase hosts your app, it will
   automatically handle the special `__/auth` path.
1. Use `signInWithPopup` which doesn't depend on third-party cookies.
1. If your frontend is not hosted on Firebase, proxy requests from
   `https://myapp.com/__auth/*` to `https://myapp.firebaseapp.com/__/auth/*`
   so there's no cross-domain concerns.
1. Download the relevant files from
   `https://myapp.firebaseapp.com/__/auth/*` and "self-host" them on
   your app.
1. Handle provider auth by yourself.

In my case, I'm not hosting the website on Firebase, and I don't want to
use `signInWithPupup`, so the proxy looks like a solid option.

In a Next.js app, it's as easy as adding the following to
`next.config.js`:

```js
module.exports = {
  async rewrites () {
    return {
      beforeFiles: [
        {
          source: '/__/auth/:path*',
          destination: `https://myapp.firebaseapp.com/__/auth/:path*`
        }
      ]
    }
  }
}
```
