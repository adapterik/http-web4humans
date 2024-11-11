## Design of the crawler

## Handling Bugginess

There are at least two factors making the cern crawler buggy:

- ancient, "incorrect", inconsistent html occasionally triggers errors
- cern site occasionally refuses connections

### Ancient HTML

The cern site was written before any kind of standardization of HTML. I'll have an analysis of that on the site at some point; it is interesting to consider. Until I've identified all or enough of the inconsistencies, there may be crashes of the crawler, or more probably skipping of valid pages and links.

### cern site refuses connections

After a number of requests, the cern site will refuse connections. The reason is unknown - it could be a buggy server, a very slow machine, or a rate limiter kicking in. So let us ignore the reason for now and focus on the behavior.

The crawler does account for this, with trying 3 times for a request, with a pause between tries. If all tries fail, the url is skipped.

## Fault Tolerance

During a crawling run, a page may be skipped. This can occur due to:

- bugs in the crawler
- the page access times out (all retries exhausted)
- the page itself cannot be accessed at all (404)

A failure may be permanent or temporary. A missing page is permanent. A bug or 

Since most crawling (other than the initial home page) is due to links from other pages, a single page failure essentially corrupts the entire site crawl.

Permanant faileu

## HTML Errors

The following errors have been encountered:

- no html wrapper tag
- no head wrapper tag
- no body wrapper tag
- invalid tag "header" used to wrap title tag
- "nextid" invalid tag used (part of next html editor)
- attribute values not always quoted

## Link Errors

- missing linked resources

## Usage

Within devcontainer:

```shell
ruby tools/fetchers/cern/fetcher.rb http://info.cern.ch temp/crawl_data
```
