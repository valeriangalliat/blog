# Invoking a Firebase callable function from the Firebase Admin SDK
May 15, 2024

[LOL you can't](https://stackoverflow.com/a/65061421/4324668).

What you [_can_](https://stackoverflow.com/a/65062301/4324668) do
however is using the Firebase Admin SDK to create a custom token for the
client SDK, and use the client SDK to make the call. 🙃

What does this looks like?

```js
const admin = require('firebase-admin')
const { initializeApp } = require('firebase/app')
const { getAuth, signInWithCustomToken } = require('firebase/auth')
const { getFunctions, httpsCallable } = require('firebase/auth')

admin.initializeApp({
  // Your admin config
})

initializeApp({
  // Your client config
})

const token = await admin.auth().createCustomToken('admin')

await signInWithCustomToken(getAuth(), token)

const result = await httpsCallable(getFunctions(), 'myCallableFunction').call({})
```

Here we created a custom token for a virtual user with UID `admin` (it
doesn't need to exist in Firebase Auth). We can verify that in the
function:

```js
const functions = require('firebase-functions')

exports.myCallableFunction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User is not authenticated'
    )
  }

  if (context.auth.uid !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'User is not authorized'
    )
  }
})
```

## Why callable instead of HTTP function?

With a [HTTP function](https://firebase.google.com/docs/functions/http-events),
we could have made a simple `fetch` request to the endpoint.

Why use a [callable function](https://firebase.google.com/docs/functions/callable)
then?

In my case, it was because callable functions have auth built-in,
whereas you're responsible to implement your own auth for HTTP
functions. I found that using a `https.onCall` function with a custom
Firebase token was more elegant than configuring some kind of internal
"API key".

## Invoking the callable function manually

It turns out it's also quite easy to invoke a callable function without
the Firebase SDK, via a [plain HTTP call](https://firebase.google.com/docs/functions/callable-reference).

With cURL, calling a function that doesn't have token authentication is
as simple as:

```sh
curl \
    -X POST \
    -H 'Content-Type: application/json' \
    'https://region-project.cloudfunctions.net/myCallableFunction' \
    --data '{"data": {}}'
```

For the authentication, we need an `Authorization: Bearer` header, but
we can't directly use the custom token we generated above. We need to
[exchange](https://stackoverflow.com/a/51346783/4324668) it for an ID
token first (this happened transparently in the previous example).

We could use the client SDK to do that for us but at that point we might
as well use the client SDK to call the function as well. 😅

Just for educational purpose, and building off the earlier example, it
would look like:

```js
const { getAuth, signInWithCustomToken, getIdToken } = require('firebase/auth')

await signInWithCustomToken(getAuth(), token)

console.log(await getIdToken(getAuth().currentUser))
```

We could then use that token in the cURL request:

```sh
curl \
    -X POST \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $token" \
    'https://region-project.cloudfunctions.net/myCallableFunction' \
    --data '{"data": {}}'
```

But if we're calling the function via `fetch`, it's probably that we
don't want to use the client SDK. Then, exchanging the token would
look like [this](https://cloud.google.com/identity-platform/docs/use-rest-api#section-verify-custom-token):

```sh
curl \
    -X POST \
    -H 'Content-Type: application/json' \
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=$firebaseApiKey" \
    --data "{\"token\": \"$customToken\", \"returnSecureToken\": true}"
```

This returns an `idToken` that we can use as `Authorization: Bearer` in
the invocation of the callable function as seen above.

<div class="note">

**Note:** if you're wondering about `returnSecureToken`, it's
[documented](https://cloud.google.com/identity-platform/docs/use-rest-api#section-verify-custom-token)
as "should always be true".

Without it, the endpoint returns only an `idToken` with no `expiresIn`
nor `refreshToken`, so my guess is that it's a token that... doesn't
expire? Which is considered insecure.

</div>
