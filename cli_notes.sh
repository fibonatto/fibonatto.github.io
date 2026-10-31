#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_URL="https://fibonatto.github.io"
GITHUB_URL="https://github.com/fiBonatto"
SITE_NAME="Bonatto"
SITE_IMAGE="$SITE_URL/SEO.png"
YEAR="$(date +%Y)"
OUTPUT="$ROOT/notes"

if [ "$#" -ne 1 ]; then
    printf 'Usage: %s /path/to/programming-notes\n' "${0##*/}" >&2
    exit 2
fi

SOURCE="$(cd "$1" && pwd)"
if [ ! -d "$SOURCE" ]; then
    printf 'error: source directory does not exist: %s\n' "$1" >&2
    exit 1
fi

command -v pandoc >/dev/null 2>&1 || {
    echo 'error: pandoc is required' >&2
    exit 1
}

SEP=$'\x1f'
TMP="$(mktemp)"
BODY_TMP=""
trap 'rm -f "$TMP" "$BODY_TMP" 2>/dev/null || true' EXIT

escape_html() {
    printf '%s' "$1" |
        sed \
            -e 's/\&/\&amp;/g' \
            -e 's/</\&lt;/g' \
            -e 's/>/\&gt;/g' \
            -e 's/"/\&quot;/g'
}

get_org_keyword() {
    local key="$1" file="$2"
    awk -v key="$key" '
        { sub(/\r$/, "") }
        /^[[:space:]]*$/ { next }
        !/^#\+/ { exit }
        {
            line = $0
            sub(/^#\+/, "", line)
            name = line
            sub(/:.*/, "", name)
            if (tolower(name) == tolower(key)) {
                sub(/^[^:]*:[[:space:]]*/, "", line)
                sub(/[[:space:]]+$/, "", line)
                print line
                exit
            }
        }
    ' "$file"
}

first_org_heading() {
    awk '/^\*+[[:space:]]/ { sub(/^\*+[[:space:]]*/, ""); print; exit }' "$1"
}

slugify() {
    printf '%s' "$1" |
        tr '[:upper:]' '[:lower:]' |
        sed \
            -e 's/++/ plus plus /g' \
            -e 's/+ / plus /g' \
            -e 's/+/ plus /g' \
            -e 's/_/-/g' \
            -e 's/[^a-z0-9.-]/-/g' \
            -e 's/--*/-/g' \
            -e 's/^-//' \
            -e 's/-$//'
}

# Category slug, then source path: preserves the NN_ prefix order.
sorted_records() {
    LC_ALL=C sort -t "$SEP" -k1,1 -k5,5 "$TMP"
}

print_css() {
    cat <<'CSS'
html {
  color: #4A505E;
  background: #FAF5E5;
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
  font-size: 17px;
  line-height: 1.5;
}

main { flex: 1; }
a { color: #BD7948; }

img, svg {
  max-width: 100%;
  height: auto;
}

footer {
  margin-top: 3em;
  color: #8E8E88;
  font-size: 0.85em;
  text-align: center;
}

.notes-list { padding-left: 1.4em; }
.notes-list li { margin: 0.15em 0; }
.category { margin-top: 1.8em; }

table {
  display: block;
  max-width: 100%;
  margin: 1.5em 0;
  overflow-x: auto;
  border-collapse: collapse;
  font-size: 0.95em;
}
th, td {
  padding: 0.4em 0.75em;
  border: 1px solid #8E8E88;
  text-align: left;
  vertical-align: top;
}
th {
  background: rgba(74, 80, 94, 0.08);
  font-weight: bold;
}

pre {
  max-width: 100%;
  margin: 1.5em 0;
  padding: 0.9em 1em;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  line-height: 1.4;
  background: rgba(74, 80, 94, 0.07);
  border: 1px solid rgba(74, 80, 94, 0.18);
  border-radius: 4px;
}
pre code {
  padding: 0;
  background: none;
  border: 0;
  white-space: inherit;
}
code {
  font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  font-size: 0.85em;
}
:not(pre) > code {
  padding: 0.1em 0.35em;
  background: rgba(74, 80, 94, 0.09);
  border-radius: 3px;
}
div.sourceCode { margin: 1.5em 0; }
div.sourceCode pre { margin: 0; }

code span.kw, code span.cf { color: #9A4F26; font-weight: bold; }
code span.dt { color: #3E6E8E; }
code span.dv, code span.bn, code span.fl, code span.cn { color: #8A5FA0; }
code span.st, code span.ch, code span.vs, code span.ss, code span.sc { color: #5E7D3A; }
code span.co, code span.do, code span.an, code span.cv, code span.in { color: #77776F; font-style: italic; }
code span.fu, code span.bu, code span.ex { color: #2F6F73; }
code span.pp, code span.im { color: #A0522D; }
code span.op, code span.ot { color: #4A505E; }
code span.er, code span.al { color: #B3261E; font-weight: bold; }

math { font-size: 1.05em; }
math[display="block"] {
  display: block math;
  margin: 1.2em 0;
  max-width: 100%;
  overflow-x: auto;
}
CSS
}

# print_head TITLE DESCRIPTION CANONICAL_URL OG_TYPE [PUBLISHED]
print_head() {
    local title="$1"
    local description="$2"
    local canonical="$3"
    local og_type="$4"
    local published="${5:-}"

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

    printf '  <link rel="icon" type="image/svg+xml" sizes="any" href="/favicon.svg">\n\n'

    printf '  <style>\n'
    print_css
    printf '  </style>\n\n'

    printf '  <link\n'
    printf '    rel="alternate"\n'
    printf '    type="application/rss+xml"\n'
    printf '    title="%s"\n' "$SITE_NAME"
    printf '    href="/rss.xml"\n'
    printf '  >\n'
    printf '</head>\n'
}

# Collect .org files directly under each subject directory. Root-level files,
# README.org files, and non-Org files are intentionally excluded.
while IFS= read -r -d '' category_dir; do
    category_name="$(basename "$category_dir")"
    category_slug="$(slugify "$category_name")"

    while IFS= read -r -d '' file; do
        base="$(basename "$file" .org)"
        rel="${file#"$SOURCE"/}"
        file_slug="$(slugify "$base")"

        title="$(get_org_keyword title "$file")"
        if [ -z "$title" ]; then
            title="$(first_org_heading "$file" || true)"
        fi
        if [ -z "$title" ]; then
            title="$base"
        fi

        description="$(get_org_keyword description "$file")"
        [ -n "$description" ] || description="__NO_DESCRIPTION__"

        raw_date="$(get_org_keyword date "$file")"
        date=""
        if [[ "$raw_date" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
            date="${BASH_REMATCH[0]}"
        fi
        [ -n "$date" ] || date="__NO_DATE__"

        output_rel="$category_slug/$file_slug.html"

        printf '%s%s%s%s%s%s%s%s%s%s%s%s%s\n' \
            "$category_slug" "$SEP" \
            "$category_name" "$SEP" \
            "$title" "$SEP" \
            "$description" "$SEP" \
            "$rel" "$SEP" \
            "$output_rel" "$SEP" \
            "$date" >> "$TMP"
    done < <(find "$category_dir" -type f -name '*.org' ! -name 'README.org' -print0)
done < <(find "$SOURCE" -mindepth 1 -maxdepth 1 -type d -print0)

if [ ! -s "$TMP" ]; then
    echo 'error: no category .org files found' >&2
    exit 1
fi

# Rebuild generated output only after source discovery succeeded.
rm -rf "$OUTPUT"
mkdir -p "$OUTPUT"

# Generate each note page.
while IFS="$SEP" read -r category_slug category_name title description rel output_rel date; do
    [ -n "$output_rel" ] || continue
    [ "$description" != "__NO_DESCRIPTION__" ] || description=""
    [ "$date" != "__NO_DATE__" ] || date=""

    published=""
    [ -z "$date" ] || published="${date}T00:00:00-03:00"

    source="$SOURCE/$rel"
    output="$OUTPUT/$output_rel"
    mkdir -p "$(dirname "$output")"
    BODY_TMP="$(mktemp)"

    pandoc \
        --from org \
        --shift-heading-level-by=1 \
        --syntax-highlighting=pygments \
        --math-method=mathml \
        --to html \
        "$source" \
        -o "$BODY_TMP"

    canonical="$SITE_URL/notes/$output_rel"
    {
        print_head "$title" "$description" "$canonical" "article" "$published"
        cat <<'EOF'

<body>

<nav aria-label="Primary navigation">
  <a href="/">Home</a>
  <a href="/notes/">Notes</a>
  <a href="/rss.xml">RSS</a>
</nav>

<main>
  <article>
EOF
        printf '    <h1>%s</h1>\n' "$(escape_html "$title")"
        cat "$BODY_TMP"
        cat <<EOF
  </article>
</main>

<footer>
  © $YEAR <a href="/">Bonatto</a> • Vim powered • <a href="$GITHUB_URL" target="_blank" rel="noopener noreferrer">GitHub</a>
</footer>

</body>
</html>
EOF
    } > "$output"

    rm -f "$BODY_TMP"
    BODY_TMP=""
done < <(sorted_records)

# Generate the single, complete notes index with direct links to every note.
{
    print_head "Notes" "Programming notes organized by subject." "$SITE_URL/notes/" "website"
    cat <<'EOF'

<body>

<header>
  <h1>Notes</h1>
  <p>Programming languages, computer science, and software engineering.</p>
</header>

<nav aria-label="Primary navigation">
  <a href="/">Home</a>
  <a href="/notes/" aria-current="page">Notes</a>
  <a href="/rss.xml">RSS</a>
</nav>

<main>
EOF

    current_category=""
    while IFS="$SEP" read -r category_slug category_name title description rel output_rel date; do
        [ -n "$output_rel" ] || continue
        if [ "$category_slug" != "$current_category" ]; then
            if [ -n "$current_category" ]; then
                printf '    </ul>\n  </section>\n'
            fi
            current_category="$category_slug"
            printf '  <section class="category" id="%s">\n' "$(escape_html "$category_slug")"
            printf '    <h2>%s</h2>\n' "$(escape_html "$category_name")"
            printf '    <ul class="notes-list">\n'
        fi
        printf '      <li><a href="/notes/%s">%s</a></li>\n' \
            "$(escape_html "$output_rel")" "$(escape_html "$title")"
    done < <(sorted_records)

    [ -z "$current_category" ] || printf '    </ul>\n  </section>\n'

    cat <<EOF
</main>

<footer>
  © $YEAR <a href="/">Bonatto</a> • Vim powered • <a href="$GITHUB_URL" target="_blank" rel="noopener noreferrer">GitHub</a>
</footer>

</body>
</html>
EOF
} > "$OUTPUT/index.html"

echo "Generated:"
echo "  notes   → $OUTPUT"
echo "  index   → $OUTPUT/index.html"
echo "  pages   → $(wc -l < "$TMP" | tr -d ' ')"
