You are a Staff Software Architect, Systems Engineer, and Principal Technical Writer. Your exact task is to perform a rigorous, code-first reverse-engineering analysis of this repository and write the definitive, production-ready technical documentation directly into a file named `review2.md`.

CRITICAL CONTROL PARAMETERS:
1. THE SOURCE CODE IS THE ONLY SOURCE OF TRUTH. Ignore completely: `README.md`, any previous report, comments describing intended behavior, or editor artifacts. Assume all existing documentation is wrong.
2. DO NOT include any conversational meta-text, prefaces, or postfaces (e.g., "Sure, here is the documentation..."). The output must start directly with the markdown title of the document.
3. Every single architectural claim must list the exact file, function name, struct, or compiler flag backing it. If intent cannot be proven from code, state: "Reason cannot be determined from the implementation."

---

Generate `review2.md` adhering strictly to the following structure:

# Technical Architecture Documentation: review2.md

## 1. Executive Summary & Taxonomy
* **System Categorization:** Formally classify the architecture based on how execution and rendering are handled. Address why it is a Client-Side SPA Engine with Build-Time Materialization (Content-as-Binary) rather than a standard Static Site Generator (SSG).

## 2. Core Subsystems & Codebase Map
Provide a factual breakdown of each subsystem, documenting its explicit responsibility, key data structures, and core functions:
* **Build-Time Pipeline:** Focus on `tools/packer.c` (how it compiles content into raw C-arrays in `generated/contents_data.h`) and `build.sh` (flag optimization such as `-Oz`, `-flto`, and SHA256 assets hashing).
* **Memory & Execution Subsystem:** `src/main.c`, `src/buffer.c` / `include/buffer.h`.
* **State & Routing Subsystem:** `src/router.c`.
* **Parsing & Transpilation Core:** `src/markdown.c` (zero-allocation state-machine parser via string views) and `src/math.c` (recursive descent LaTeX parser to MathML).
* **UI Layout & Configuration:** `src/ui.c`, `src/pages.c`, and `src/config.c` (Nord palette, constants).
* **Dead/Isolated Code:** Document `./heart.c` at the root, confirming its actual location, isolation from the build, and memory leaks. Document `config.plist` properly as a Clang/LLVM diagnostics/LSP artifact, NOT an editor layout backup.

## 3. The WASM/JS Boundary & FFI Architecture
* **Exported Surface (WASM → JS):** Detail all functions exposed via `EMSCRIPTEN_KEEPALIVE` (`_main`, `_ui_toggle_theme`, `_switch_page`, `_handle_route`, `_handle_current_route`, `_draw_frame`).
* **Imported Capabilities (JS → WASM):** Detail the Hardware Abstraction Layer (HAL) implemented via `EM_JS` macros in `src/js_api.c` for DOM manipulation (`sys_set_html`), LocalStorage persistence, and 2D Canvas graphics.
* **Data Marshalling Protocol:** Explicitly document how strings cross the boundary via pointers using `UTF8ToString` and how the JS layer reads member offsets of C structures directly from memory using pointer arithmetic and `HEAP32`.

## 4. Memory Model & Lifecycle Lifecycle
* **Allocation Policy:** Document the zero-malloc runtime footprint. Trace the residency of data in the `.rodata` section.
* **The Global Buffer Mechanics:** Detail the exact boundary limits of the 128KB static global accumulator `g_html_buf` and how safety limits are handled during parsing expansion.
* **Execution Lifecycle Flow:** Outline the step-by-step síncronous execution path: Bootstrap -> Module Init -> Router Hooking -> Global State Page Mutation -> Buffer Reset -> Parser Flush -> Atomic DOM Hydration (`replaceChildren`).

## 5. Performance-Oriented Design Decisions
Document only optimizations observable in code: fixed-size buffers, omission of memory allocators, zero-allocation tokenization, compile-time content packing, and compiler optimization flags.
