# Download end-to-end encrypted chats from Messenger
November 22, 2026

I like to periodically archive my data from online platforms,
just in case something happens and they lose whatever I had
on there (in the case of Messenger, my chat history).

This shit definitely happens in the wild, like
[that time Google Drive lost months of data for some users](https://www.bleepingcomputer.com/news/google/google-drive-users-angry-over-losing-months-of-stored-data/). 💀

Facebook's plaintext chats are already part of Meta's own
[**Export your information**](https://accountscenter.meta.com/info_and_permissions/dyi)
tool, and that one seems OK.

However end-to-end encrypted chats need to be exported separately, from
Messenger in **Privacy & safety > End-to-end encrypted chats > Message storage > [Download message storage data](https://www.facebook.com/secure_storage/dyi)**.

But in my experience ([and not just mine apparently](https://www.reddit.com/r/computerforensics/comments/1tqgypj/facebook_messenger_end_to_end_encrypted_messages/))
those exports are half broken, missing random conversations and
attachments. I could _not_ get it to do a proper export that actually
contains all my data.

So I made a [Messenger Archive](https://github.com/valeriangalliat/messenger-archive),
a browser extension that reuses the same underlying mechanism as
Messenger's own export tool, but that _actually_ works.

Not sure if it's gonna keep working in the future if Facebook updates
whatever functions the extension relies on, but as of today it allowed
me to export all my chats and their attachments. Sharing in case it can
be useful to anyone else.
