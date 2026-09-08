---
title: XSS attempts fixture
status: scoped
type: fixture
created: 2026-05-13
updated: 2026-05-13
---

# XSS attempts

<script>alert('raw block')</script>

[unsafe javascript](javascript:alert(1))

[unsafe file](file:///etc/passwd)

[unsafe absolute path](/etc/passwd)

[unsafe traversal](../../private.txt)

![remote fetch](https://example.invalid/tracker.png)

[attribute injection](https://example.com){#evil .evil data-evil=yes style="color:red"}

<img src=x onerror="alert(1)">

<iframe src="https://example.com"></iframe>

The renderer must strip or neutralise every payload below. None of these
should survive into the rendered HTML body as executable HTML or JS.
The render smoke lint runs this file through `spade-render` and inspects the output to confirm.

## Inline script tag

<script>alert(1)</script>

## Image with event handler

<img src=x onerror=alert(1)>

## Anchor with javascript: URL

[click me](javascript:alert(1))

## markdown-it-attrs-style attribute injection

[label]{onclick=alert(1) .pill}

## Inline style with expression (legacy IE; harmless but still flag)

<div style="background:url(javascript:alert(1))">x</div>

## Body content

Regular body text follows to confirm the renderer keeps going past the
payloads above.
