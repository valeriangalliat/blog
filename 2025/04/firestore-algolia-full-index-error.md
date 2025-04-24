# Firestore Algolia full index operation error 400 or 403
April 23, 2025

I was testing a change to the Algolia setup in a staging environment and
needed to perform a full index.

## Triggering a full index

BTW to trigger a full index, either change the Algolia extension config
from the Firebase console, and make sure that the **Full Index existing
documents** field is set to true.

If it's already on true (so that won't trigger an actual config change)
and you don't want to change anything else in the config, you can set it
to false, wait 5 minutes for it to deploy, then set it to true again
(lol). Or, better, go in Google Cloud Console, in Cloud Task, and for
the `ext-firestore-algolia-search-executeFullIndexOperation` task queue,
select **Actions > Force a task run**.

## Errors during full index

I was looking at the
`ext-firestore-algolia-search-executeFullIndexOperation` Cloud Function
logs to monitor the index operation, and after a few minutes it choked
with a 400 error (but I've also seen 403).

The logs are really unhelpful because the request body gets logged
entirely first, but in my case it's too big truncates the log line, and
so if this function logs the response body (which I'm not even sure),
it's not accessible because the line got truncated in the request part.

It took me longer than I'm willing to admit to figure that, but I found
out that there's a **API Monitoring** section on Algolia where we can
**Search API Logs** and I could see the 400 and 403 errors there!

In my case the errors were:

```json
{
  "message": "Record at the position ... objectID=... is too big size=.../10000 bytes. Please have a look at https://www.algolia.com/doc/guides/sending-and-managing-data/prepare-your-data/in-depth/index-and-records-size-and-usage-limitations/#record-size-limits",
  "status": 400
}
```

```json
{
  "message": "You have exceeded your Record quota. You’ll need to change your plan for more capacity, or delete records. See more details at https://www.algolia.com/account/billing/details?applicationId=...",
  "status": 403
}
```

That's much more useful.

Turns out my staging env had too many records already for its plan (free
plan) so I couldn't sync more during the full index, and in another case
the record I was trying to write was too big for the free plan max
record size.

I wasn't having the error in prod because we use a paid plan there.

So the solution was simple. Upgrade staging to a paid plan so I can do
my testing!

After that I triggered a full index again and it worked just fine. 🙏
