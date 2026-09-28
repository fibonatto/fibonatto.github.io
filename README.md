# fibonatto.github.io

Personal website and technical blog of Sergio Bonatto.

The site is intentionally implemented as a static, dependency-light web application. Markdown files are used as the source of content and are converted into standalone HTML pages with Pandoc.

## Structure

```text
.
├── contents/          # Markdown source files
│   ├── archive/       # Archived posts
│   ├── quick/         # Short-form drafts
│   └── trash/         # Unpublished or discarded content
├── post/              # Generated HTML posts
├── index.html         # Generated homepage
├── rss.xml            # Generated RSS feed
├── style.css          # Generated site stylesheet
├── favicon.svg
├── llms.txt           # Machine-readable site index
├── cli_post.sh        # Site generator
└── README.md
```

## Content

Posts are written in Markdown with YAML front matter:

```yaml
---
title: "Post title"
date: "2026-09-27"
description: "Short description of the post."
---
```

The generator extracts the `title`, `date`, and `description` fields to build the homepage, RSS feed, and `llms.txt`.

## Build

The site is generated with:

```sh
./cli_post.sh
```

The script:

1. Reads Markdown files from `contents/`.
2. Converts each post to standalone HTML using Pandoc.
3. Generates the homepage from post metadata.
4. Generates the RSS feed.
5. Generates the site stylesheet.
6. Generates `llms.txt`.
7. Injects navigation, favicon references, and the footer into generated posts.

The generated files are written directly to the repository root and `post/`.

## Dependencies

The build requires:

* Bash
* Pandoc
* standard POSIX command-line utilities
* BSD `date` with `-j` and `-f` support

The generated site itself has no JavaScript runtime or server-side component.

## Design

The website is deliberately minimal. It uses semantic HTML, a small stylesheet, system/browser fonts, and static resources.

There is no frontend framework, client-side router, JavaScript application layer, or external content-management system.

The repository therefore contains both the source content and the complete generated representation served by the web server.

