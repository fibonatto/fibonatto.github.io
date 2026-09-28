#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENTS="$ROOT/contents"
POSTS="$ROOT/post"
INDEX="$ROOT/index.html"
RSS="$ROOT/rss.xml"
SITEMAP="$ROOT/sitemap.xml"
ROBOTS="$ROOT/robots.txt"
LLMS="$ROOT/llms.txt"

SITE_NAME="Bonatto"
SITE_URL="https://fibonatto.github.io"
GITHUB_URL="https://github.com/fiBonatto"
SITE_DESCRIPTION="Work spans formal methods, functional programming, and operating systems."
SITE_IMAGE="$SITE_URL/SEO.png"
YEAR="$(date +%Y)"

# Non-whitespace field separator: keeps empty fields (e.g. missing description)
# from collapsing when read back with `read`.
SEP=$'\x1f'

mkdir -p "$POSTS"

# ==============================================================================
# Helpers
# ==============================================================================

# Reads a key from the YAML frontmatter only (the block between the first two
# `---` lines). Lines in the post body are never matched.
get_frontmatter() {
    local key="$1"
    local file="$2"
    local value

    value="$(
        awk -v key="$key" '
            { sub(/\r$/, "") }
            NR == 1 { if ($0 == "---") next; exit }
            $0 == "---" || $0 == "..." { exit }
            index($0, key ":") == 1 {
                sub(/^[^:]*:[[:space:]]*/, "")
                print
                exit
            }
        ' "$file"
    )"

    case "$value" in
        \"*\")
            value="${value#\"}"
            value="${value%\"}"
            ;;
        \'*\')
            value="${value#\'}"
            value="${value%\'}"
            ;;
    esac

    printf '%s' "$value" |
        sed -e 's/\\"/"/g'
}

escape_html() {
    printf '%s' "$1" |
        sed \
            -e 's/&/\&amp;/g' \
            -e 's/</\&lt;/g' \
            -e 's/>/\&gt;/g' \
            -e 's/"/\&quot;/g'
}

escape_xml() {
    printf '%s' "$1" |
        sed \
            -e 's/&/\&amp;/g' \
            -e 's/</\&lt;/g' \
            -e 's/>/\&gt;/g' \
            -e 's/"/\&quot;/g' \
            -e "s/'/\&apos;/g"
}

# Works with both GNU date (Linux) and BSD date (macOS).
rss_date() {
    local date="$1"

    if date -d "$date" >/dev/null 2>&1; then
        LC_ALL=C date -d "$date" "+%a, %d %b %Y 00:00:00 -0300"
    else
        LC_ALL=C date -j -f "%Y-%m-%d" "$date" "+%a, %d %b %Y 00:00:00 -0300"
    fi
}

# Posts sorted newest first; ties broken by name so the order is deterministic.
sorted_posts() {
    sort -r -t "$SEP" -k1,1 -k4,4 "$TMP"
}

print_css() {
    cat <<'CSS'
html {
  color: #000;
  background: #fff;
}

body {
  min-height: 100vh;
  box-sizing: border-box;
  max-width: 44em;
  margin: 0 auto;
  padding: 2em 1.5em;

  display: flex;
  flex-direction: column;

  overflow-wrap: break-word;

  font-family: "Times New Roman", Times, serif;
  font-size: 18px;
  line-height: 1.5;
}

main {
  flex: 1;
}

a {
  color: #315f70;
}


pre {
  max-width: 100%;
  margin: 1.5em 0;

  white-space: pre-wrap;
  overflow-wrap: anywhere;

  line-height: 1.35;
}

pre code {
  white-space: inherit;
}

img,
svg {
  max-width: 100%;
  height: auto;
}

time {
  color: #707070;
  font-size: 0.85em;
  font-weight: normal;
}

footer {
  margin-top: 3em;
  color: #707070;
  font-size: 0.85em;
  text-align: center;
}

.post-list h3 {
  margin-bottom: 0;
}

.post-list p {
  margin-top: 0.25em;
}
CSS
}

# print_head TITLE DESCRIPTION CANONICAL_URL OG_TYPE ASSET_PREFIX [PUBLISHED]
#   ASSET_PREFIX: "" for the index, "../" for pages under post/
#   PUBLISHED:    ISO timestamp, only for articles
print_head() {
    local title="$1"
    local description="$2"
    local canonical="$3"
    local og_type="$4"
    local prefix="$5"
    local published="${6:-}"

    local title_html description_html
    title_html="$(escape_html "$title")"
    description_html="$(escape_html "$description")"

    printf '<!DOCTYPE html>\n'
    printf '<html lang="en">\n'
    printf '<head>\n'
    printf '  <meta charset="utf-8">\n'
    printf '  <meta name="viewport" content="width=device-width, initial-scale=1">\n\n'

    printf '  <title>%s</title>\n' "$title_html"
    if [ -n "$description" ]; then
        printf '  <meta name="description" content="%s">\n' "$description_html"
    fi
    printf '  <meta name="author" content="Sergio Bonatto">\n'
    if [ "$og_type" = "website" ]; then
        printf '  <meta name="google-site-verification" content="YZt--bJGFhf1puUTMa3odpocmGWn3v5bRppUsbXeJeA">\n'
    fi

    printf '\n  <link rel="canonical" href="%s">\n\n' "$canonical"

    printf '  <meta property="og:title" content="%s">\n' "$title_html"
    if [ -n "$description" ]; then
        printf '  <meta property="og:description" content="%s">\n' "$description_html"
    fi
    printf '  <meta property="og:type" content="%s">\n' "$og_type"
    printf '  <meta property="og:site_name" content="%s">\n' "$SITE_NAME"
    printf '  <meta property="og:image" content="%s">\n' "$SITE_IMAGE"
    printf '  <meta property="og:url" content="%s">\n' "$canonical"
    if [ -n "$published" ]; then
        printf '  <meta property="article:published_time" content="%s">\n' "$published"
    fi

    printf '\n  <meta name="twitter:card" content="summary_large_image">\n'
    printf '  <meta name="twitter:site" content="@fibonatto">\n'
    printf '  <meta name="twitter:creator" content="@fibonatto">\n'
    printf '  <meta name="twitter:title" content="%s">\n' "$title_html"
    if [ -n "$description" ]; then
        printf '  <meta name="twitter:description" content="%s">\n' "$description_html"
    fi
    printf '  <meta name="twitter:image" content="%s">\n\n' "$SITE_IMAGE"

    printf '  <link rel="icon" type="image/svg+xml" sizes="any" href="%sfavicon.svg">\n\n' "$prefix"

    printf '  <style>\n'
    print_css
    printf '  </style>\n\n'

    printf '  <link\n'
    printf '    rel="alternate"\n'
    printf '    type="application/rss+xml"\n'
    printf '    title="%s"\n' "$SITE_NAME"
    printf '    href="%srss.xml"\n' "$prefix"
    printf '  >\n'
    printf '</head>\n'
}

# ==============================================================================
# Temporary files
# ==============================================================================

TMP="$(mktemp)"
BODY_TMP=""
trap 'rm -f "$TMP" "$BODY_TMP" 2>/dev/null || true' EXIT

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

    if ! [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "warning: date '$date' in $file is not YYYY-MM-DD" >&2
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

    printf '%s%s%s%s%s%s%s\n' \
        "$date" "$SEP" \
        "$title" "$SEP" \
        "$description" "$SEP" \
        "$name" >> "$TMP"
done

# ==============================================================================
# Generate post pages
# ==============================================================================

rm -f "$POSTS"/*.html

while IFS="$SEP" read -r date title description name; do
    [ -n "$name" ] || continue

    source="$CONTENTS/$name.md"
    output="$POSTS/$name.html"
    BODY_TMP="$(mktemp)"

    pandoc \
        --syntax-highlighting=none \
        --to html \
        "$source" \
        -o "$BODY_TMP"

    canonical_url="$SITE_URL/post/$name.html"
    published="${date}T00:00:00-03:00"

    {
        print_head "$title" "$description" "$canonical_url" "article" "../" "$published"

        cat <<'EOF'

<body>

<nav aria-label="Primary navigation">
  <a href="../index.html">Home</a>
  <a href="../rss.xml">RSS</a>
</nav>

<main>
  <article>
EOF

        # pandoc without --standalone ignores the frontmatter title; only add
        # an <h1> when the body doesn't already provide one.
        if ! grep -qi '<h1' "$BODY_TMP"; then
            printf '  <h1>%s</h1>\n' "$(escape_html "$title")"
        fi

        cat "$BODY_TMP"

        cat <<EOF
  </article>
</main>

<footer>
  © $YEAR <a href="$SITE_URL/">Bonatto</a> • Vim powered • <a href="$GITHUB_URL" target="_blank" rel="noopener noreferrer">GitHub</a>
</footer>

</body>
</html>
EOF
    } > "$output"

    rm -f "$BODY_TMP"
    BODY_TMP=""
done < <(sorted_posts)

# ==============================================================================
# Generate index.html
# ==============================================================================

{
    print_head "$SITE_NAME" "$SITE_DESCRIPTION" "$SITE_URL/" "website" ""

    cat <<'EOF'

<body>

<header>
  <h1>Bonatto</h1>
  <p>Software Engineer · Programming Languages · Systems · Type Theory</p>
</header>

<nav aria-label="Primary navigation">
  <a href="index.html" aria-current="page">Home</a>
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

  <ul class="post-list">
EOF

    sorted_posts |
        while IFS="$SEP" read -r date title description name; do
            safe_title="$(escape_html "$title")"
            safe_description="$(escape_html "$description")"

            printf '    <li>\n'
            printf '      <article>\n'
            printf '        <time datetime="%s">%s</time> <a href="post/%s.html">%s</a>\n' \
                "$date" "$date" "$name" "$safe_title"

            if [ -n "$description" ]; then
                printf '        <p>%s</p>\n' "$safe_description"
            fi

            printf '      </article>\n'
            printf '    </li>\n\n'
        done

    cat <<EOF
  </ul>
</main>

<footer>
  © $YEAR <a href="./">Bonatto</a> • Vim powered • <a href="$GITHUB_URL" target="_blank" rel="noopener noreferrer">GitHub</a>
</footer>

</body>
</html>
EOF
} > "$INDEX"

# ==============================================================================
# Generate rss.xml
# ==============================================================================

{
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>$SITE_NAME</title>
    <link>$SITE_URL/</link>
    <description>Bonatto's blog.</description>
    <language>en</language>
    <atom:link href="$SITE_URL/rss.xml" rel="self" type="application/rss+xml" />
EOF

    sorted_posts |
        while IFS="$SEP" read -r date title description name; do
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

            if [ -n "$description" ]; then
                printf '      <description>%s</description>\n' "$safe_description"
            fi

            printf '    </item>\n'
        done

    cat <<'EOF'

  </channel>
</rss>
EOF
} > "$RSS"

# ==============================================================================
# Generate sitemap.xml
# ==============================================================================

{
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>$SITE_URL/</loc>
  </url>
EOF

    sorted_posts |
        while IFS="$SEP" read -r date title description name; do
            url="$SITE_URL/post/$name.html"
            printf '  <url>\n'
            printf '    <loc>%s</loc>\n' "$(escape_xml "$url")"
            printf '    <lastmod>%s</lastmod>\n' "$date"
            printf '  </url>\n'
        done

    cat <<'EOF'
</urlset>
EOF
} > "$SITEMAP"

# ==============================================================================
# Generate robots.txt
# ==============================================================================

cat > "$ROBOTS" <<EOF
User-agent: *
Allow: /

Sitemap: $SITE_URL/sitemap.xml
EOF

# ==============================================================================
# Generate llms.txt
# ==============================================================================

{
    cat <<EOF
# $SITE_NAME

> Software Engineer writing about programming languages, systems, type theory, and other technical subjects.

This site contains static HTML pages with the complete text of each post.

## Blog

- [Blog]($SITE_URL/): Full-text static version of the blog.
- [RSS]($SITE_URL/rss.xml): RSS feed for new posts.
EOF

    if [ -s "$TMP" ]; then
        printf '\n## Posts\n'
    fi

    sorted_posts |
        while IFS="$SEP" read -r date title description name; do
            url="$SITE_URL/post/$name.html"

            if [ -n "$description" ]; then
                printf '\n- [%s](%s): %s\n' "$title" "$url" "$description"
            else
                printf '\n- [%s](%s)\n' "$title" "$url"
            fi
        done
} > "$LLMS"

# ==============================================================================
# Done
# ==============================================================================

echo "Generated:"
echo "  posts   → $POSTS"
echo "  index   → $INDEX"
echo "  rss     → $RSS"
echo "  sitemap → $SITEMAP"
echo "  robots  → $ROBOTS"
echo "  llms    → $LLMS"
