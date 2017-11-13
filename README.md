# check_proxy_http_url.sh
This Nagios® compatible plugin allows you to check allowed/blocked URLs. It is an alternative to standard *check_http*

## Why an alternative to *check_http*?

First, *check_http* which handles poorly proxies and 302 redirections.

Also, Nagios® standard *check_http* doesn't checks whether a page is blocked or accessible. It checks whether the webserver answers or doesn't answer on a specific page. Although you can specify whether answering is OK or CRITICAL, you can't specify that you *want* a 40X as OK (or CRITICAL). For example, 403 is never a CRITICAL nor a OK, it's a WARNING and you can't do anything about it.

With *check_proxy_http_url*, you **can** check URLs through a proxy, follow correctly 302 redirections, and specify whether a specific page being accessible is either a good OR a bad thing. This is especially useful when you block certains pages with an Internet proxy and you want to make sure that theses pages are indeed blocked.

## Installation

This pluggin relies on *wget* binary, which is available on most systems for now. In the future, *cURL* option will probably also available as it tends to replace *wget*.

Aside from wget and bash, there are no prerequisites.

## Usage
```
/var/lib/nrpe/plugins/check_proxy_http_url.sh -u TARGET_URL [-p PROXY_ADDRESS:PROXY_PORT] [-r] [-v]
```

## Example output
```
[root@lanhost ~]# /var/lib/nrpe/plugins/check_proxy_http_url.sh -u some_forbidden_website.com -r
OK: URL some_forbidden_website.com isn't available and it shouldn't - 403

[root@lanhost ~]# /var/lib/nrpe/plugins/check_proxy_http_url.sh -p internal_proxy:8181 -u some_allowed_website_that_isnt_accessible.com
CRITICAL: URL some_allowed_website_that_isnt_accessible.com isn't available and it should - 403
```
