# Firebase Auth Admin SDK denied when using application default credentials
May 5, 2024

If you're using the Firebase Admin SDK from your development machine
e.g. to run ad hoc scripts, you may have tried to do something like
this:

```js
import admin from 'firebase-admin'
import { applicationDefault } from 'firebase-admin/app'

admin.initializeApp({
  projectId: 'my-project',
  credential: applicationDefault()
})

const auth = admin.auth()

const user = await auth.getUserByEmail('foo@bar.com')

console.log(user)
```

After all, it works just fine with other Firebase APIs like Firestore.

But in the above case, you'd be getting the following error (spread onto
lines for readability):

```
FirebaseAuthError: //cloud.google.com/docs/authentication/.

If you are getting this error with curl or similar tools, you may need
to specify 'X-Goog-User-Project' HTTP header for quota and billing
purposes.

For more information regarding 'X-Goog-User-Project' header, please
check https://cloud.google.com/apis/docs/system-parameters.

Raw server response:

{
  "error": {
    "code": 403,
    "message": "Your application has authenticated using end user credentials from the Google Cloud SDK or Google Cloud Shell which are not supported by the identitytoolkit.googleapis.com. We recommend configuring the billing/quota_project setting in gcloud or using a service account through the auth/impersonate_service_account setting. For more information about service accounts and how to use them in your application, see https://cloud.google.com/docs/authentication/. If you are getting this error with curl or similar tools, you may need to specify 'X-Goog-User-Project' HTTP header for quota and billing purposes. For more information regarding 'X-Goog-User-Project' header, please check https://cloud.google.com/apis/docs/system-parameters.",
    "errors": [
      {
        "message": "Your application has authenticated using end user credentials from the Google Cloud SDK or Google Cloud Shell which are not supported by the identitytoolkit.googleapis.com. We recommend configuring the billing/quota_project setting in gcloud or using a service account through the auth/impersonate_service_account setting. For more information about service accounts and how to use them in your application, see https://cloud.google.com/docs/authentication/. If you are getting this error with curl or similar tools, you may need to specify 'X-Goog-User-Project' HTTP header for quota and billing purposes. For more information regarding 'X-Goog-User-Project' header, please check https://cloud.google.com/apis/docs/system-parameters.",
        "domain": "usageLimits",
        "reason": "accessNotConfigured",
        "extendedHelp": "https://console.developers.google.com"
      }
    ],
    "status": "PERMISSION_DENIED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "SERVICE_DISABLED",
        "domain": "googleapis.com",
        "metadata": {
          "service": "identitytoolkit.googleapis.com",
          "consumer": "projects/123456"
        }
      }
    ]
  }
}
}
```

So what's going on? Well `applicationDefault()` works with the
application default credentials as created by
[`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login),
which live in `~/.config/gcloud/application_default_credentials.json`.

In my case, those credentials didn't have access to Firebase Auth for a
reason I did not try to understand.

However, what _did_ have access to Firebase Auth is the application
default credentials as created by [`firebase login`](https://firebase.google.com/docs/cli#sign-in-test-cli),
which live in `~/.config/firebase/*_application_default_credentials.json`.

Firebase's `applicationDefault()`, despite being a method of the
Firebase SDK, [does _not_ know](https://github.com/firebase/firebase-admin-node/blob/ddcf965511e2f03853bad7658b5c61b85c306580/src/app/credential-internal.ts#L485)
about the Firebase application default credentials, and instead only
uses the Google Cloud credentials. 😅

However it supports reading the credentials file from the
`GOOGLE_APPLICATION_CREDENTIALS` environment variable, so we can run the
script like this:

```sh
GOOGLE_APPLICATION_CREDENTIALS=~/.config/firebase/*_application_default_credentials.json node script.js
```

<div class="note">

**Note:** I left a wildcard `*` in the path above because Firebase
application default credentials contain your user and organization name.
It'll work out of the box if you are only connected to a single Firebase
identity, but you'll have to be more specific otherwise.

</div>
