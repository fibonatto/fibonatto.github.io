#include "config.h"

const struct timing_config timing = {.tick_delta = 0.016f};

const char *palette[16] = {
    "#2f3238", /* 0 dark bg */
    "#44484f", /* 1 dark guide */
    "#8d949c", /* 2 dark gutter */

    "#F2F1EE", /* 3 light bg */
    "#e4e0d7", /* 4 light guide (grid line) */
    "#9A9CA1", /* 5 light gutter */

    "#cfd3d8", /* 6 dark text */
    "#7a8088", /* 7 dark dim */

    "#1c3d72", /* 8 light text (pen blue) */
    "#767A80", /* 9 light dim */

    "#78a4c4", /* 10 dark accent */
    "#5B8FA8", /* 11 light accent */

    "#a98abf", /* 12 purple */
    "#8eae7a", /* 13 green */
    "#c0392b", /* 14 red (pen red) */
    "#c9ad79"  /* 15 yellow */
};

const struct theme theme_dark = {.bg	      = 0,
				 .text	      = 6,
				 .dim_text    = 7,
				 .accent      = 10,
				 .code_bg     = 0,
				 .code_border = 1};

const struct theme theme_light = {.bg	       = 3,
				  .text	       = 8,
				  .dim_text    = 9,
				  .accent      = 14,
				  .code_bg     = 3,
				  .code_border = 4};

const struct header_config header = {
    .title = "Bonatto",
    .home_label = "home",
    .blog_label = "blog",
    .light_label = "light",
    .dark_label = "dark",
    .container_id = "header-nav",
    .home_id = "nav-home",
    .blog_id = "nav-blog",
    .theme_id = "theme-toggle",
    .container_style =
        "position:fixed;top:0;width:100%;background-color:var(--bg-color);"
        "z-index:1000;padding:10px 40px;border-bottom:1px solid var(--grid-color);"
        "display:flex;justify-content:space-between;align-items:center;box-sizing:border-box;",
    .item_style = "font-size:18px;user-select:none;cursor:pointer;"
                  "color:var(--text-color);text-decoration:none;"
};

const char *css_feed = "padding: 20px; max-width: 900px; margin-top: 100px; "
		       "min-height: calc(100vh - 180px - 100px);";

const char *css_footer =
    "width: 100%; padding: 24px 0; display: flex; flex-direction: column; "
    "align-items: center; justify-content: space-between; "
    "color: var(--text-color); "
    "font-size: 18px; margin-top: 40px;";

const char *msg_whoami	   = "About";
const char *msg_github_url = "https://github.com/fiBonatto";

const char *msg_bio =
    "I am a software engineer because programming turned out to be the best way I know to understand things. \n"
    "Whether I am studying programming languages, writing software, exploring theology, or writing poetry, I find myself asking the same questions about structure, meaning, and first principles. \n"
    "This site is where those explorations converge.\n";

const char *msg_seo =
    "Software engineer specialized in programming languages, compilers, formal "
    "methods, "
    "type systems, virtual machines, operating systems, and systems "
    "programming using "
    "C, Haskell, Rust, and TypeScript. Work includes Bend, HVM, Kind, Higher "
    "Order "
    "Company tooling, and Agoriz, with emphasis on dependent types, proof "
    "systems, "
    "interpreters, runtime architecture, memory management, distributed "
    "systems, "
    "functional computation, and minimalist kernel development.";

const char *msg_404_title = "404 - NOT FOUND";
const char *msg_404_body =
    "The page you are looking for does not exist or has been moved.";

const char *code_block_pre = "background:var(--code-bg-color);"
			     "padding:16px;"
			     "border-radius:0;"
			     "overflow-x:auto;"
			     "border:1px solid var(--code-border-color);"
			     "margin:20px 0;";

const char *code_block_code = "font-family:'Courier New',monospace;"
			      "font-size:0.9rem;"
			      "line-height:1.5;"
			      "color:var(--text-color);";
