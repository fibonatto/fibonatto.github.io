#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENTS="$ROOT/contents"
CLI="$ROOT/cli"
POSTS="$CLI/post"
INDEX="$CLI/index.html"
RSS="$CLI/rss.xml"
LLMS="$ROOT/llms.txt"

SITE_URL="https://fibonatto.github.io"
CLI_URL="$SITE_URL/cli"

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
done

# ==============================================================================
# Collect post metadata
# ==============================================================================

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

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
        "$name" >> "$tmp"
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
  <h2>Posts</h2>

  <ul>
EOF

    sort -r -k1,1 "$tmp" |
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

    cat <<'EOF'
  </ul>
</main>

</body>
</html>
EOF
} > "$INDEX"

# ==============================================================================
# Add navigation to post pages
# ==============================================================================

for post in "$POSTS"/*.html; do
    [ -f "$post" ] || continue

    tmp_post="$(mktemp)"

    awk '
        !inserted && /<body[^>]*>/ {
            print
            print ""
            print "<nav>"
            print "  <a href=\"../index.html\">Back to posts</a>"
            print "</nav>"
            inserted=1
            next
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
    <link>$CLI_URL/</link>
    <description>CLI version of Bonatto's blog.</description>
    <language>en</language>
EOF

    sort -r -k1,1 "$tmp" |
    while IFS=$'\t' read -r date title description name; do
        safe_title="$(escape_xml "$title")"
        safe_description="$(escape_xml "$description")"
        published="$(rss_date "$date")"
        url="$CLI_URL/post/$name.html"

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

The \`/cli/\` version of the blog is the preferred machine-readable representation.
It contains static HTML pages with the complete text of each post.

## CLI Blog

- [CLI Blog]($CLI_URL/): Full-text static version of the blog.
- [RSS]($CLI_URL/rss.xml): RSS feed for new posts.

## Posts
EOF

    sort -r -k1,1 "$tmp" |
    while IFS=$'\t' read -r date title description name; do
        url="$CLI_URL/post/$name.html"

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
