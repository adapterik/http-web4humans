## mechanics

- route all external links to an external link handler

- external links should be cataloged

- external link status should be recorded in the catalog

- external link status should be periodically checked, or checked on every access; an error in access should be recorded.

- bad external links should still be checked every once in a while.

- broken external links may have just been moved; if we find this is true we may need some translation layers to re-route

- we need to be able to apply new rules to re-generate pages from the source html (which we should never need to fetch again)


## mistakes to fix in documents

- no space between text and an html element; e.g. hello<a href="/world.html">world</a>

- blank space in quoted words

- blank space in link labels; at least sometimes it should be a space before the link, but ends up inside it

