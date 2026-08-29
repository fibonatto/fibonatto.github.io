#ifndef PROJECT_SRC_UI_H
#define PROJECT_SRC_UI_H

#include <stddef.h>
#include "config.h"
/*
 * add_paragraph - Appends a text paragraph to the feed element.
 * @text_ptr: pointer to the string in WASM memory
 * @len: length of the string
 */
void add_paragraph(const char *text_ptr, size_t len);

/*
 * add_code_block - Appends a code block to the feed.
 * @lang: language identifier view
 * @code: source code content view
 */
void add_code_block(struct str_view lang, struct str_view code); 
/*
 * add_image - Appends an image to the feed element.
 * @path_ptr: pointer to the image path
 * @path_len: length of the path string
 * @alt_ptr: pointer to the alt text string
 * @alt_len: length of the alt text string
 * @scale: scale factor for the image width
 * @width: explicit width for the image (0 for auto)
 * @height: explicit height for the image (0 for auto)
 * @is_lcp: whether the image is the largest contentful paint
 */
void add_image(const char *path_ptr, size_t path_len,
	       const char *alt_ptr, size_t alt_len, float scale,
	       int width, int height, int is_lcp);

void add_header_container(const char *id, const char *style);
void add_header_title(const char *text, const char *style, const char *parent_id);
void add_theme_toggle(const char *label, const char *style, const char *id,
		      const char *container_id);
void add_nav_group(const char *id, const char *container_id, const char *style);
void add_nav_link(const char *label, const char *style, const char *id,
		  const char *container_id, int is_blog);
void ui_render_header(void);

/*
 * add_footer - Appends a footer element to the body.
 * @style: CSS style string
 * @github_url: GitHub profile URL
 * @instagram_url: Instagram profile URL
 */
void add_footer(const char *style, const char *github_url,
		const char *instagram_url);

/*
 * ui_begin_render - Resets the global HTML buffer.
 */
void ui_begin_render(void);

/*
 * ui_end_render - Flushes the global HTML buffer to the feed element.
 */
void ui_end_render(void);

/*
 * clear_feed - Removes all content from the feed element.
 */
void clear_feed(void);

/*
 * add_blog_entry - Appends a blog entry link to the feed element.
 * @title: post title
 * @date: post date string
 * @slug: post URL slug
 */
void add_blog_entry(const char *title, const char *date, const char *slug);

/*
 * update_theme_toggle_label - Updates the text of the theme toggle button.
 * @label: new text
 */
void update_theme_toggle_label(const char *id, const char *label);

/*
 * ui_toggle_theme - Toggles between dark and light themes.
 */
void ui_toggle_theme(void);

/*
 * ui_init_router - Initializes the JS hashchange listener.
 */
void ui_init_router(void);

/*
 * ui_sync_url - Updates the browser URL hash.
 */
void ui_sync_url(const char *path);

/*
 * ui_get_current_hash - Returns the current URL hash into the provided buffer.
 */
void ui_get_current_hash(char *buf, int max_len);

/*
 * add_bar - Appends a segmented graph bar to the UI.
 * @height: total height in pixels
 * @width: width in pixels
 * @pcts: array of segment percentages (0.0 to 1.0)
 * @colors: array of CSS variable names for colors
 * @opacities: array of opacity values
 * @styles: array of bar_seg_style enums
 * @n: number of segments
 */
void add_bar(int height, int width, const float *pcts, const char **colors,
	     const float *opacities, const int *styles, int n);

/*
 * update_seo_metadata - Updates the document title and meta tags for SEO.
 * @title: new page title
 * @description: new page description
 * @url: canonical URL or current path
 */
void update_seo_metadata(const char *title, const char *description, const char *url);

#endif
