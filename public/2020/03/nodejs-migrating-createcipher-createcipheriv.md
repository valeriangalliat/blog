Node.js: migrating from `createCipher` to `createCipheriv`
----------------------------------------------------------
March 14, 2020

If you still use the `createCipher` and `createDecipher` methods of the
`crypto` module, you're likely getting the following deprecation
warnings when running your code:

```
(node:477082) [DEP0106] DeprecationWarning: crypto.createCipher is deprecated.
(node:468005) [DEP0106] DeprecationWarning: crypto.createDecipher is deprecated.
```

This is because this method didn't allow for passing an initialization
vector (IV), and instead derived the IV from the key using the OpenSSL
`EVP_BytesToKey` derivation function, using a `null` salt meaning that
the IV would be deterministic for a given key which is an issue for
ciphers with counter mode like CTR, GCM and CCM.

Your code might have looked like:

```js
const cipher = crypto.createCipher('aes256', key)
```

If you want to make this code backwards compatible, you need to call
OpenSSL's `EVP_BytesToKey` function yourself, typically through
[this module](https://www.npmjs.com/package/evp_bytestokey) which makes
it available in JS userland.

However the reason this function is deprecated in the first place is
because you shouldn't use it, and instead use a random unpredictable IV,
which requires you to change your code to something like this:

```js
const iv = crypto.randomBytes(16)
const cipher = crypto.createCipher('aes256', key, iv)
```

Here, for AES-256 in CBC mode (`aes256` being aliased to `AES-256-CBC` by
OpenSSL), the IV size is expected to be the same as the block size,
which is always 16 bytes.

In order to decrypt the message, you will need the IV as well. Typically
you'd store the IV together with the message, as the important part is
for the IV to not be predictable ahead of time.
