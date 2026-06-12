# EHS: Executable Hypermedia System

A high-performance, minimalist web engine for personal publishing. Compiles Markdown content into a WebAssembly binary at build time, creating a **zero-allocation, heapless runtime** that executes hypermedia without external dependencies.

**[Live Demo →](https://fibonatto.github.io/)**

---

## 🎯 Architecture Overview

EHS is fundamentally different from traditional web architectures. Rather than treating the browser as a runtime platform, it treats the WASM binary as an **embedded system**—analogous to firmware rendering hypermedia directly to the client.

```
Markdown Files (contents/)
         ↓
    [Packer]  ← Compile-time content serialization
         ↓
C Arrays (.rodata) → Embedded in WASM binary
         ↓
    [Markdown Parser] ← Zero-allocation runtime parsing
         ↓
HTML Buffer (128 KB, static)
         ↓
DOM Hydration (atomic via JS HAL)
```

### Design Philosophy

- **Content-as-Binary**: Markdown is serialized into the executable; no filesystem, no network I/O
- **Heapless Runtime**: Pre-allocated buffers, no `malloc`/`free`, deterministic memory usage
- **Executable Model**: The entire publishing system is a single, self-contained WASM module
- **Minimal JavaScript**: JS layer is strictly a Hardware Abstraction Layer (HAL) for DOM/Canvas/Storage
- **Build-Time Materialization**: All application state, content, and assets are resolved at compile time

---

## 📊 Current Metrics

| Metric | Value |
|--------|-------|
| **Repository Size** | ~8.9 MB (includes build artifacts) |
| **Language Composition** | C (96%), HTML (3.4%), Other (0.6%) |
| **WASM Binary (compressed)** | ~25 KB (Brotli) |
| **JavaScript (compressed)** | ~8 KB (Brotli) |
| **Total Cold Load** | ~33 KB transferred |
| **Time to Interactive** | <150 ms |
| **Memory Model** | Zero-alloc, 128 KB static buffer |

---

## 🏗️ System Architecture

### 1. **Build Pipeline** (`build.sh`)

#### Stage 1: Content Packing
```bash
gcc tools/packer.c -O2 -o tools/packer
./tools/packer contents > generated/contents_data.h
```

The `packer` utility:
- Scans `contents/` for Markdown files
- Parses YAML front-matter (title, date, description)
- Serializes each post as hex-encoded C arrays: `post_data_<slug>[]`
- Generates binary-searchable slug index for O(log n) lookup
- Outputs `generated/contents_data.h` with:
  - Post data arrays
  - Blog post metadata struct array (`posts[]`)
  - Slug-indexed lookup function (`find_post_index_by_slug()`)

#### Stage 2: Asset Hashing
- SHA256 fingerprinting of static assets (profile image, fonts)
- Immutable caching via content hash filenames
- Substituted into `index.html` at build time

#### Stage 3: WASM Compilation
```bash
emcc src/*.c \
  -Oz -flto \
  -s WASM=1 -s ASSERTIONS=0 -s SAFE_HEAP=0 \
  -s EXPORTED_FUNCTIONS='["_main","_switch_page","_handle_route","..."]' \
  -o build/app.js
```

Optimization flags:
- `-Oz`: Aggressive code size optimization
- `-flto`: Link-time optimization
- `-s SAFE_HEAP=0`: Disable safety checks (intentional for embedded model)
- `-s ASSERTIONS=0`: Minimal runtime overhead

#### Stage 4: Post-Processing
```bash
wasm-opt -Oz --all-features build/app.wasm -o build/app.wasm
terser build/app.js -c -m -o build/app.js
brotli -Z build/app.wasm build/app.js
```

#### Stage 5: Content Addressable Naming
- Generate SHA256 hashes for `.wasm` and `.js`
- Rename to `app.<hash>.wasm` and `app.<hash>.js`
- Patch `.js` to reference new `.wasm` hash
- Generate final `index.html` with asset URLs

---

### 2. **Core Runtime Components**

#### **Global HTML Buffer** (`src/buffer.c`)

```c
#define BUFFER_CAPACITY (128 * 1024)

typedef struct {
    char data[BUFFER_CAPACITY];
    size_t len;
    bool overflow;
} Buffer;

extern Buffer g_html_buf;
```

- **Heap-free**: Static allocation at compile time
- **Overflow detection**: Sets flag instead of crashing
- **Zero-copy rendering**: Direct `memcpy` into WASM linear memory

#### **Markdown Parser** (`src/markdown.c`)

**Zero-allocation design**:
- Line-by-line state machine
- Uses `struct str_view { const char *data; size_t len }` (pointer + length)
- No `malloc`, no `free`, no temporary allocations
- Supports:
  - Headers (h1-h6)
  - Code blocks with language syntax highlighting
  - Images with lazy loading and responsive sizing
  - Inline and display LaTeX math (`$...$` and `$$...$$`)
  - Custom graph shortcodes (`[[graph:...]]`)
  - YAML front-matter parsing

**Example parsing pipeline**:
```c
render_markdown(content);
  ├─ skip front-matter (---)
  ├─ detect code blocks (```)
  ├─ detect math blocks ($$)
  └─ render lines:
      ├─ headers (#, ##, ...)
      ├─ images (![alt](url))
      ├─ inline math & LaTeX
      └─ text with HTML escaping
```

#### **LaTeX → MathML Transpiler** (`src/math.c`)

Recursive descent parser converting LaTeX to MathML:
- **Greek letters**: `\alpha`, `\beta`, ... → `<mi>&alpha;</mi>` entities
- **Operators**: `\sum`, `\prod`, `\int`, ... → MathML operators
- **Constructs**: `\frac{a}{b}`, `\sqrt{x}`, superscripts, subscripts
- **Inline**: `$x + y$` → `<math>...</math>`
- **Display**: `$$x^2 + y^2 = z^2$$` → `<math display="block">...</math>`

Built-in command table with 80+ LaTeX commands mapped to Unicode entities.

#### **Router & State Machine** (`src/router.c`)

```c
enum page_state {
    PAGE_INITIAL,
    PAGE_HOME,
    PAGE_BLOG_INDEX,
    PAGE_ARTICLE,
    PAGE_404
};

struct site_state {
    float runtime;
    bool is_dark;
    const struct theme *theme;
    enum page_state page;
};
```

Routing logic:
- `#/` or `#/home` → Render home page
- `#/blog` → Render blog index
- `#/post/<slug>` → Lookup slug via binary search, render article
- Unknown → 404 page

Binary search on generated `post_slug_index[]`:
```
Time complexity: O(log n)
Space complexity: O(n) metadata only
```

#### **Platform Abstraction Layer (HAL)** (`src/js_api.c`)

JavaScript bridges (via `EM_JS` macros):

| Function | Purpose |
|----------|---------|
| `sys_set_html()` | Atomic DOM replacement via `createContextualFragment()` |
| `sys_set_text()` | Text content manipulation |
| `sys_set_style()` | CSS property injection |
| `sys_init_router()` | `hashchange` and `popstate` listeners |
| `sys_update_url()` | `history.pushState()` wrapper |
| `sys_get_url_hash()` | Read current location hash |
| `sys_set_meta()` | SEO metadata (og:, twitter:, description) |
| `sys_load_theme()` | Read theme from `localStorage` |
| `sys_save_theme()` | Persist theme choice |
| `init_graphics()` | Canvas initialization for header rendering |
| `update_theme_colors()` | CSS variable injection into `:root` |
| `draw_frame()` | Canvas redraw for visual effects |

**String marshalling protocol**:
- C passes pointer to WASM linear memory
- JS uses `UTF8ToString()` to read C-string
- No data copying for small strings (<4KB typical)

#### **UI Rendering** (`src/ui.c`, `src/pages.c`)

High-level rendering functions (DSL-like):
```c
void add_paragraph(const char *text, size_t len);
void add_heading(int level, const char *text, size_t len);
void add_code_block(struct str_view lang, struct str_view code);
void add_image(const char *url, size_t url_len, ...);
void add_blog_entry(const char *title, const char *date, const char *slug);
void add_bar(int h, int w, float *pcts, const char **colors, ...);
```

All functions append to `g_html_buf`, checked for overflow before DOM flush.

**Page rendering flow**:
```c
page_render_home() {
    ui_begin_render();        // Reset g_html_buf
    add_heading(1, "Sergio Bonatto", 14);
    add_image("pfp.avif", ...);
    add_paragraph(msg_bio, strlen(msg_bio));
    // ... more content
    ui_end_render();          // Atomic sys_set_html("#feed", g_html_buf.data)
}
```

#### **Theme System** (`src/config.c`)

Nord-inspired color palette with light/dark variants:

```c
const struct theme theme_dark = {
    .bg = 0,              // Nord 0 (#2e3440)
    .text = 4,            // Nord 4 (#eceff4)
    .dim_text = 3,        // Nord 3 (#4c566a)
    .accent = 8,          // Nord 8 (#88c0d0)
    .code_bg = 1,         // Nord 1 (#3b4252)
    .code_border = 2      // Nord 2 (#434c5e)
};
```

CSS variables injected at runtime:
```css
--bg-color
--text-color
--dim-text-color
--accent-color
--code-bg-color
--code-border-color
--nord0 through --nord15
```

---

### 3. **Execution Model**

#### Synchronous Rendering Pipeline

Every page transition follows:

1. **Router Match**
   ```c
   handle_route("#/blog")
     └─ switch_page(true)
   ```

2. **Buffer Reset**
   ```c
   ui_begin_render()
     └─ buf_reset(&g_html_buf)  // len = 0, overflow = false
   ```

3. **Content Generation**
   ```c
   page_render_blog()
     ├─ add_heading(1, "Blog", 4)
     ├─ for each post:
     │   └─ add_blog_entry(posts[i].title, posts[i].date, posts[i].slug)
   ```

4. **DOM Hydration**
   ```c
   ui_end_render()
     └─ sys_set_html("#feed", g_html_buf.data)
        └─ JS: document.querySelector("#feed").replaceChildren(fragment)
   ```

**Deterministic timing**: Page transitions complete in <50ms (all parsing, rendering, and DOM ops synchronous).

#### Lazy Image Loading

In `sys_set_html()`, placeholders are upgraded:

```javascript
el.querySelectorAll('.img-placeholder').forEach(ph => {
    const img = new Image();
    img.src = ph.dataset.src;
    img.loading = ph.dataset.lcp ? 'eager' : 'lazy';
    if (ph.dataset.lcp) img.fetchpriority = 'high';
    ph.replaceWith(img);
});
```

**LCP Optimization**: Hero images marked with `is_lcp=1` get `fetchpriority="high"` and `loading="eager"`.

---

## 📁 Project Structure

```
.
├── src/                      # Runtime implementation (C)
│   ├── main.c               # Entry point & bootstrap
│   ├── buffer.c             # Fixed-size HTML buffer
│   ├── markdown.c           # Zero-alloc Markdown parser
│   ├── math.c               # LaTeX → MathML transpiler
│   ├── router.c             # SPA routing logic
│   ├── ui.c                 # UI rendering DSL
│   ├── pages.c              # Page templates
│   ├── config.c             # Theme & constants
│   ├── render.c             # Graphics/Canvas
│   └── js_api.c             # JavaScript HAL (EM_JS)
│
├── include/                 # Public headers
│   ├── buffer.h
│   ├── markdown.h
│   ├── math.h
│   ├── router.h
│   ├── state.h
│   ├── ui.h
│   ├── config.h
│   ├── pages.h
│   ├── render.h
│   └── sys.h
│
├── tools/                   # Build utilities
│   └── packer.c            # Content serializer (generates contents_data.h)
│
├── contents/                # Markdown source (user-provided)
│   ├── post1.md
│   ├── post2.md
│   └── ...
│
├── public/                  # Static assets
│   ├── pfp.avif            # Profile image
│   ├── Virgil.woff2         # Font
│   └── SEO.png              # OG image
│
├── generated/               # Build outputs (generated)
│   ├── contents_data.h      # Serialized posts + index
│   └── assets.h             # Asset hashes
│
├── build/                   # Compiled artifacts
│   ├── app.<hash>.wasm      # WebAssembly module
│   ├── app.<hash>.js        # Emscripten glue code
│   ├── app.<hash>.wasm.br   # Brotli-compressed
│   └── app.<hash>.js.br
│
├── index.template.html      # HTML template (substituted at build time)
├── index.html               # Final output (git-ignored)
├── build.sh                 # Build orchestration script
├── compile_commands.json    # clangd LSP configuration
└── README.md               # This file
```

---

## 🚀 Getting Started

### Prerequisites

```bash
# Emscripten SDK (for WASM compilation)
brew install emscripten  # macOS
apt install emscripten   # Ubuntu/Debian

# WASM optimization
brew install binaryen    # macOS
apt install binaryen     # Ubuntu/Debian

# Additional tools
npm install -g terser    # JS minification
brew install brotli      # Brotli compression
```

### Adding Content

Create a Markdown file in `contents/`:

```markdown
---
title: My First Post
date: 2026-06-12
description: A brief description for SEO
---

# My First Post

This is my content. I can use **Markdown** and $\LaTeX$ math.

## Math Example

Inline: $E = mc^2$

Display:
$$
\frac{\partial f}{\partial x} = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}
$$

## Code Example

\`\`\`python
def hello():
    print("Hello, world!")
\`\`\`

## Images

![My alt text](https://example.com/image.jpg)
```

### Building

```bash
chmod +x build.sh
./build.sh
```

Output:
- `index.html` (ready to deploy)
- `build/app.<hash>.wasm` and `build/app.<hash>.js` (referenced in HTML)

### Local Testing

```bash
# Using Python's built-in server (or any static server)
python3 -m http.server 8000
open http://localhost:8000
```

### Deployment

```bash
# GitHub Pages (push index.html and build/ to gh-pages branch)
git push origin main:gh-pages

# Or any static host (Netlify, Vercel, etc.)
# Just deploy the directory as-is
```

---

## 🔍 Architecture Patterns

### 1. **Arena Allocator Pattern**
Global buffer with overflow flag:
```c
Buffer g_html_buf = {
    .data = { /* 128 KB */ },
    .len = 0,
    .overflow = false
};
```
- No malloc/free
- Deterministic memory usage
- Predictable performance

### 2. **String Views (Pointer + Length)**
Instead of C-strings, pass views:
```c
struct str_view {
    const char *data;
    size_t len;
};

// No strlen() needed, no null termination required
render_text(view.data, view.len);
```

### 3. **Read-Only Data Segment**
All content lives in `.rodata`:
```c
static const char post_data_slug_name[] = {
    0x23, 0x20, 0x54, 0x69, 0x74, 0x6c, 0x65,  // "# Title"
    // ... hex-encoded Markdown
    0x00
};
```
- No runtime allocation
- Immutable by design
- Page faults → cache hits

### 4. **Binary Search Index**
```c
// Generated by packer
struct { const char *slug; int index; } post_slug_index[] = {
    { "article_a", 0 },
    { "article_b", 1 },
    { "article_c", 2 },
    // ... sorted by slug
};

// O(log n) lookup
int idx = find_post_index_by_slug("article_b");  // → 1
```

---

## 🛠️ Development

### Editing Code

Use an LSP-compatible editor with clangd:

```bash
# Generate LSP config
emcc src/*.c -Iinclude -Igenerated -DEMSCRIPTEN -MJ config.json
```

Recommended editors:
- VS Code (Clangd extension)
- Vim/Neovim (coc-clangd)
- Emacs (lsp-mode)

### Debugging

Enable debug symbols (optional, increases binary size):

```bash
# In build.sh, add -g flag
emcc src/*.c -Oz -g -o build/app.js
```

View WASM in browser DevTools:
1. Open DevTools → Sources
2. Navigate to WebAssembly section
3. View disassembly or set breakpoints

### Profiling

```javascript
// In console, measure render time
performance.mark('route-start');
Module._switch_page(true);
performance.mark('route-end');
performance.measure('route', 'route-start', 'route-end');
console.log(performance.getEntriesByName('route')[0].duration);
```

---

## 📈 Performance Characteristics

### Memory Profile
- **Heap**: 0 bytes (post-bootstrap)
- **Static Buffer**: 128 KB (fixed)
- **WASM Linear Memory**: ~256 KB total
- **Deterministic**: Every page identical memory footprint

### Computation Profile
- **Cold Start**: ~100ms (module load + initial render)
- **Page Transition**: ~30ms (parse + render + DOM update)
- **Route Lookup**: O(log n) ≈ 0.1ms for typical blog size
- **Markdown Parse**: ~5-10ms per 50KB content

### Network Profile
- **Initial Load**: ~33 KB (Brotli-compressed)
- **Per-Page**: 0 bytes (all content pre-cached in binary)
- **Cache Strategy**: Content hash → immutable, cache forever

---

## 🎨 Customization

### Changing Colors

Edit `src/config.c`:

```c
const struct theme theme_dark = {
    .bg = 0,              // Change to Nord palette index
    .text = 4,
    // ... etc
};

// Update palette mapping if needed
const char *palette[16] = {
    "#2e3440",  // 0: Nord 0
    "#3b4252",  // 1: Nord 1
    // ... etc
};
```

### Adding New Pages

Create new `page_render_*()` functions in `src/pages.c`:

```c
void page_render_projects(void) {
    ui_begin_render();
    add_heading(1, "Projects", 8);
    add_paragraph("My projects", 11);
    // ... more content
    ui_end_render();
}
```

Update router in `src/router.c`:

```c
if (strcmp(path, "#/projects") == 0) {
    state.page = PAGE_PROJECTS;
    page_render_projects();
}
```

### Custom Graph Shortcodes

Syntax: `[[graph:h,w;pct,color,opacity,style;...]]`

Example:
```markdown
[[graph:100,200;0.5,--nord8,1.0,s;0.3,--nord9,0.8,h;0.2,--nord10,0.6]]
```

Renders a segmented bar graph (height 100px, width 200px) with three segments.

---

## 🔧 Known Limitations & Future Work

### Current Limitations
- ✓ **No dynamic content loading** (all content must be in `contents/` at build time)
- ✓ **Limited Markdown support** (CommonMark not 100% compliant)
- ✓ **No search** (would require full-text index in binary)
- ✓ **No comments** (static deployment model)

### Future Enhancements
- [ ] Full CommonMark compliance
- [ ] Syntax highlighting for code blocks
- [ ] Table support
- [ ] Footnotes & citations
- [ ] Search index (bloom filters?)
- [ ] Dark mode auto-detection (prefers-color-scheme)
- [ ] PWA support (service worker)

---

## 📚 References & Learning

### Papers & Articles
- **Embedded Systems Design**: Patterns used here mirror firmware UI systems
- **WASM Performance**: Optimizations inspired by game engine architecture
- **Zero-Allocation Algorithms**: Research from systems programming literature

### Related Projects
- [Hugo](https://gohugo.io/) — Traditional SSG (for comparison)
- [Zola](https://www.getzola.org/) — Rust-based SSG
- [11ty](https://www.11ty.dev/) — Flexible SSG

---

## 📝 License

MIT (implied, no LICENSE file currently present)

---

## 🤝 Contributing

Found a bug or have an idea? Open an issue or submit a PR.

Current areas for contribution:
- CommonMark compliance improvements
- Performance optimizations
- Documentation & examples

---

**Questions?** Check the architecture documentation or open a discussion.

**Live Site**: [fibonatto.github.io](https://fibonatto.github.io/)

---

## Acknowledgments

Built with:
- [Emscripten](https://emscripten.org/) — C to WASM compiler
- [Binaryen](https://github.com/WebAssembly/binaryen) — WASM optimizer
- [Nord Theme](https://www.nordtheme.com/) — Color palette
