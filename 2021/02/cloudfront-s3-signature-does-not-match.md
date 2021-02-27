CloudFront and S3: `SignatureDoesNotMatch`, the request signature we calculated does not match the signature you provided
=========================================================================================================================
February 26, 2021

Maybe you're getting the following error from your CloudFront
distribution like it happened to me.

```xml
<Error>
  <Code>SignatureDoesNotMatch</Code>
  <Message>The request signature we calculated does not match the signature you provided. Check your key and signing method.</Message>
</Error>
```

If so, maybe like me you configured the `Managed-AllViewer` origin
request policy, which forwards all the headers, cookies and query string
parameters to the origin.

The issue is, if your origin is S3, something between CloudFront and S3
doesn't expect all the headers, cookies and query string parameters to
be passed and they don't compute the signature in the same way,
resulting in the above error.

This means you can't use the `Managed-AllViewer` request policy if your
origin is S3.

If like me you need to access extra headers or query string parameters
from a Lambda@Edge (which you won't be able to unless your request
policy sends those), you can try making a custom request policy to
whitelist only the headers and query parameters that you need. This did
the trick for me!
