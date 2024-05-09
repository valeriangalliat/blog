# Jest and Firestore: could not reach Cloud Firestore backend
May 8, 2024

So you're using Jest to do some unit tests that involve testing
Firebase-related stuff like Firestore, maybe Firestore rules with
[`@firebase/rules-unit-testing`](https://firebase.google.com/docs/rules/unit-tests)?

But your test just times out:

```
thrown: "Exceeded timeout of 5000 ms for a test.
Add a timeout value to this test to increase the timeout, if this is a long-running test. See https://jestjs.io/docs/api#testname-fn-timeout."
```

So you go on and add a longer timeout value to the test, but then you
hit another level of timeout:

```
@firebase/firestore: Firestore: Could not reach Cloud Firestore backend. Backend didn't respond within 10 seconds.
This typically indicates that your device does not have a healthy Internet connection at the moment. The client will operate in offline mode until it is able to successfully connect to the backend.
```

By any chance, are you using [`jest-environment-jsdom`](https://jestjs.io/docs/next/tutorial-jquery)?
Something like this in your `jest.config.js`:

```js
module.exports = {
  testEnvironment: 'jsdom'
  // testEnvironment: 'jest-environment-jsdom'
}
```

If so, look no further. Firestore doesn't like what
`jest-environment-jsdom` does to the global object and makes it hang
forever.

It took me long enough to figure _that_ out, so I didn't manage to
figure out _why_ exactly it's the case. So far my understanding is that
it's related to the `fetch` API _somehow_, because if you set the
undocumented `useFetchStreams` option to `false` in the Firebase client,
then it falls back to `XMLHttpRequest` (which jsdom implements) and
things work again.

```js
user.firestore({ useFetchStreams: false, merge: true })
```

My advice would be to run the Firestore tests in the default Node.js
environment instead of the jsdom environment. This may be by using a
dedicated `jest.config.js`, or simply running your Firestore tests
separately from the rest of your frontend test suite and passing `--env
node` to override the value from `jest.config.js`:

```sh
npx jest --env node firestore.test.js
```

Last resort, the `useFetchStreams` hack above should do it. 😄
