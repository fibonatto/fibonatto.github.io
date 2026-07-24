#ifndef PROJECT_SRC_CONFIG_H
#define PROJECT_SRC_CONFIG_H

#include <stdbool.h>
#include <stdio.h>

struct timing_config {
	float tick_delta;
};

extern const struct timing_config timing;

extern const char *palette[16];

struct theme {
	int bg;
	int text;
	int dim_text;
	int accent;
	int code_bg;
	int code_border;
};

extern const struct theme theme_dark;
extern const struct theme theme_light;

struct header_config {
	const char *title;
	const char *home_label;
	const char *blog_label;
	const char *light_label;
	const char *dark_label;
	const char *container_id;
	const char *home_id;
	const char *blog_id;
	const char *theme_id;
	const char *container_style;
	const char *item_style;
	const char *title_style;
};

extern const struct header_config header;

extern const char *css_feed;
extern const char *css_footer;

struct blog_post {
	const char *title;
	const char *date;
	const char *slug;
	const char *description;
};

struct str_view {
	const char *data;
	size_t len;
};

struct text_span {
	const char *ptr;
	size_t len;
};
enum bar_seg_style {
	BAR_SEG_SOLID,
	BAR_SEG_HATCHED,
	BAR_SEG_EMPTY,
};

struct bar_segment {
	float pct;
	const char *color_var;
	float opacity;
	enum bar_seg_style style;
};


extern const struct blog_post posts[];
extern const int posts_count;
int find_post_index_by_slug(const char *slug);

#define UI_HEADER_HEIGHT 180

extern const char *msg_whoami;
extern const char *msg_bio;
extern const char *msg_seo;
extern const char *msg_github_url;
extern const char *msg_404_title;
extern const char *msg_404_body;
extern const char *code_block_pre;
extern const char *code_block_code;

#endif
