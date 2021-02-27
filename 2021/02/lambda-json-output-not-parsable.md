The Lambda function returned invalid JSON: the JSON output is not parsable
==========================================================================
February 26, 2021

There could be a number of reasons you're getting this error message
from your CloudFront distribution with a Lambda@Edge configured.

For example, your Lambda function could actually be returning a poorly
encoded response. But if you know you're returning proper JSON, why
could you get that error?

Well, it turns out this error message is *also* a way for AWS to tell
you that the (absolutely valid) JSON that your Lambda function returned
was too big.

Indeed, [a Lambda@Edge is limited to a 40 kB response body][limit],
which is not a lot of kB if you ask me.

[limit]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-at-the-edge-exposing-body-size-limits-lambda-at-edge

And instead of returning a meaningful error when this happens (I
confirmed in my case, this was the issue), we're getting an invalid JSON
error.

Why? Maybe something in the stack of things involved on AWS between
CloudFront and the Lambda function just *truncates* the response body to
40 kB, and a truncated JSON is indeed invalid JSON.

Regardless, if you're getting this error on a Lambda@Edge, it's worth
checking your payload size, and it might save you hours of debugging
your JSON structure and what could corrupt it!

Cheers!
