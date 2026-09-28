#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENTS="$ROOT/contents"
POSTS="$ROOT/post"
INDEX="$ROOT/index.html"
RSS="$ROOT/rss.xml"
LLMS="$ROOT/llms.txt"
SITE_URL="https://fibonatto.github.io"
GITHUB_URL="https://github.com/fiBonatto"
YEAR="$(date +%Y)"

mkdir -p "$POSTS"

# ==============================================================================
# Helpers
# ==============================================================================

get_frontmatter() {
    local key="$1"
    local file="$2"

    sed -n \
        "s/^${key}:[[:space:]]*\"\{0,1\}\([^\"\$]*\)\"\{0,1\}[[:space:]]*$/\1/p" \
        "$file" |
        head -n 1
}

escape_xml() {
    printf '%s' "$1" |
        sed \
            -e 's/&/\&amp;/g' \
            -e 's/</\&lt;/g' \
            -e 's/>/\&gt;/g'
}

rss_date() {
    local date="$1"

    LC_ALL=C date \
        -j \
        -f "%Y-%m-%d" \
        "$date" \
        "+%a, %d %b %Y 00:00:00 -0300"
}

print_css() {
    cat <<'EOF'
html {
  color: #000;
  background-color: #fff;
}

body {
  min-height: 100vh;
  box-sizing: border-box;
  margin: 0 auto;
  max-width: 44em;
  padding: 40px 30px;

  display: flex;
  flex-direction: column;

  overflow-wrap: break-word;

  font-family: Georgia, "Times New Roman", serif;
  font-size: 17px;
  line-height: 1.55;
}

a {
  color: #356273;
}

pre {
  min-height: 8em;
  margin: 1.5em 0;

  display: flex;
  align-items: center;
  justify-content: flex-start;

  overflow: hidden;
  line-height: 1;
}

pre code {
  text-align: left;
}

img,
svg {
  max-width: 100%;
}

time,
.date {
  color: #777;
  font-size: 0.9em;
}

main {
  flex: 1;
}

footer {
  margin-top: 3em;
  color: #777;
  font-size: 0.9em;
  text-align: center;
}
EOF
}

# ==============================================================================
# Temporary files
# ==============================================================================

TMP="$(mktemp)"
CSS_TMP="$(mktemp)"

trap 'rm -f "$TMP" "$CSS_TMP"' EXIT

print_css > "$CSS_TMP"

# ==============================================================================
# Collect post metadata
# ==============================================================================

for file in "$CONTENTS"/*.md; do
    [ -f "$file" ] || continue

    date="$(get_frontmatter "date" "$file")"
    title="$(get_frontmatter "title" "$file")"
    description="$(get_frontmatter "description" "$file")"

    if [ -z "$date" ]; then
        echo "warning: no date found in $file" >&2
        continue
    fi

    if [ -z "$title" ]; then
        title="$(sed -n 's/^#[[:space:]]\(.*\)$/\1/p' "$file" | head -n 1)"
    fi

    if [ -z "$title" ]; then
        echo "warning: no title found in $file" >&2
        continue
    fi

    if [ -z "$description" ]; then
        echo "warning: no description found in $file" >&2
    fi

    name="$(basename "$file" .md)"

    printf '%s\t%s\t%s\t%s\n' \
        "$date" \
        "$title" \
        "$description" \
        "$name" >> "$TMP"
done

# ==============================================================================
# Generate post pages
# ==============================================================================

rm -f "$POSTS"/*.html

for file in "$CONTENTS"/*.md; do
    [ -f "$file" ] || continue

    name="$(basename "$file" .md)"

    pandoc \
        --standalone \
        "$file" \
        -o "$POSTS/$name.html"

    tmp_post="$(mktemp)"

    CSS_TMP="$CSS_TMP" perl -0pe '
        BEGIN {
            open my $fh, "<", $ENV{CSS_TMP}
                or die "cannot open CSS: $!\n";

            local $/;
            $css = <$fh>;

            close $fh;
        }

        s{</head>}{"  <style>\n" . $css . "  </style>\n</head>"}e
    ' "$POSTS/$name.html" > "$tmp_post"

    mv "$tmp_post" "$POSTS/$name.html"
done

# ==============================================================================
# Generate index.html
# ==============================================================================

{
    cat <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <title>Bonatto</title>

  <meta name="google-site-verification" content="YZt--bJGFhf1puUTMa3odpocmGWn3v5bRppUsbXeJeA">
  <meta name="author" content="Sergio Bonatto">

  <meta property="og:title" content="Bonatto">
  <meta property="og:description" content="Work spans formal methods, functional programming, and operating systems.">
  <meta property="og:type" content="website">
  <meta property="og:image" content="https://fibonatto.github.io/SEO.png">
  <meta property="og:url" content="https://fibonatto.github.io/">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:site" content="@fibonatto">
  <meta name="twitter:creator" content="@fibonatto">
  <meta name="twitter:title" content="Bonatto">
  <meta name="twitter:description" content="Work spans formal methods, functional programming, and operating systems.">
  <meta name="twitter:image" content="https://fibonatto.github.io/SEO.png">

  <link rel="icon" type="image/svg+xml" sizes="any" href="favicon.svg">

  <style>
EOF

    print_css

    cat <<'EOF'
  </style>

  <link
    rel="alternate"
    type="application/rss+xml"
    title="Bonatto"
    href="rss.xml"
  >
</head>

<body>

<header>
  <h1>Bonatto</h1>
  <p>Software Engineer · Programming Languages · Systems · Type Theory</p>
</header>

<nav>
  <a href="index.html">Home</a>
  <a href="rss.xml">RSS</a>
</nav>

<main>
  <p>
    I am a software engineer because programming turned out to be the best way I know to understand things.
  </p>

  <p>
    Whether I am studying programming languages, writing software, exploring theology, or writing poetry, I find myself asking the same questions about structure, meaning, and first principles.
  </p>

  <p>
    This site is where those explorations converge.
  </p>

  <h2>Blog</h2>

  <ul>
EOF

    sort -r -k1,1 "$TMP" |
    while IFS=$'\t' read -r date title description name; do
        safe_title="$(escape_xml "$title")"
        safe_description="$(escape_xml "$description")"

        printf '    <li>\n'

        printf '      <time datetime="%s">%s</time>\n' \
            "$date" \
            "$date"

        printf '      <a href="post/%s.html">%s</a>\n' \
            "$name" \
            "$safe_title"

        if [ -n "$description" ]; then
            printf '      <p>%s</p>\n' \
                "$safe_description"
        fi

        printf '    </li>\n'
        printf '\n'
    done

    cat <<EOF
  </ul>
</main>

<footer>
  © $YEAR <a href="$SITE_URL">Bonatto</a> • Vim powered • <a href="$GITHUB_URL" target="_blank" rel="noopener noreferrer">GitHub</a>
</footer>

</body>
</html>
EOF
} > "$INDEX"

# ==============================================================================
# Add navigation and footer to post pages
# ==============================================================================

for post in "$POSTS"/*.html; do
    [ -f "$post" ] || continue

    tmp_post="$(mktemp)"

    awk \
        -v year="$YEAR" \
        -v site_url="$SITE_URL" \
        -v github_url="$GITHUB_URL" '
        !nav_inserted && /<body[^>]*>/ {
            print
            print ""
            print "<nav>"
            print "  <a href=\"../index.html\">Back to posts</a>"
            print "</nav>"
            nav_inserted=1
            next
        }

        /<\/body>/ && !footer_inserted {
            print "<footer>"
            printf "  © %s <a href=\"%s\">Bonatto</a> • Vim powered • <a href=\"%s\" target=\"_blank\" rel=\"noopener noreferrer\">GitHub</a>\n", year, site_url, github_url
            print "</footer>"
            print ""
            footer_inserted=1
        }

        { print }
    ' "$post" > "$tmp_post"

    mv "$tmp_post" "$post"
done

# ==============================================================================
# Generate rss.xml
# ==============================================================================

{
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Bonatto</title>
    <link>$SITE_URL/</link>
    <description>Bonatto's blog.</description>
    <language>en</language>
EOF

    sort -r -k1,1 "$TMP" |
    while IFS=$'\t' read -r date title description name; do
        safe_title="$(escape_xml "$title")"
        safe_description="$(escape_xml "$description")"
        published="$(rss_date "$date")"
        url="$SITE_URL/post/$name.html"

        printf '\n'
        printf '    <item>\n'
        printf '      <title>%s</title>\n' "$safe_title"
        printf '      <link>%s</link>\n' "$url"
        printf '      <guid isPermaLink="true">%s</guid>\n' "$url"
        printf '      <pubDate>%s</pubDate>\n' "$published"
        printf '      <description>%s</description>\n' "$safe_description"
        printf '    </item>\n'
    done

    cat <<'EOF'

  </channel>
</rss>
EOF
} > "$RSS"

# ==============================================================================
# Generate llms.txt
# ==============================================================================

{
    cat <<EOF
# Bonatto

> Software Engineer writing about programming languages, systems, type theory, and other technical subjects.

This site contains static HTML pages with the complete text of each post.

## Blog

- [Blog]($SITE_URL/): Full-text static version of the blog.
- [RSS]($SITE_URL/rss.xml): RSS feed for new posts.

## Posts
EOF

    sort -r -k1,1 "$TMP" |
    while IFS=$'\t' read -r date title description name; do
        url="$SITE_URL/post/$name.html"

        if [ -n "$description" ]; then
            printf '\n- [%s](%s): %s\n' \
                "$title" \
                "$url" \
                "$description"
        else
            printf '\n- [%s](%s)\n' \
                "$title" \
                "$url"
        fi
    done
} > "$LLMS"

# ==============================================================================
# Done
# ==============================================================================

echo "Generated:"
echo "  posts → $POSTS"
echo "  index → $INDEX"
echo "  rss   → $RSS"
echo "  llms  → $LLMS"
