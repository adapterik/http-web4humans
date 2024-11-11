# Fetchers

What is a fetcher?

A Ruby program to fetch, parse, repair, and store a web site we want to preserve.

We have the following tools:

- `fetcher.rb`: Fetches an entire web site by crawling it. Usage `ruby tools/fetcher.rb https://example.com "sites/example_com` to fetch `example.dom`, storing the contents in the directory `site/example_com`

- `fix-bad-tags.rb`: Attempts to fix incorrect tags in html files; catches things like missing end tag, incorrect end tag

- `fix-bad-images.rb`: Replaces image source urls with a url to a local "missing image" image.

- `fix-bad-links.rb`: fixes some cases of bad links; missing local url is replaced with a link to a generated 404 page for this site; missing external link similarly

- `report-problems.rb`: reports both fixable and unfixable problems in the html files.