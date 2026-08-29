#include <stdio.h>
#include <string.h>
#include <emscripten.h>
#include "config.h"
#include "state.h"
#include "buffer.h"
#include "sys.h"
#include "render.h"
#include "ui.h"
#include "markdown.h"

static bool is_safe_css_var_name(const char *name) {
	if (!name || name[0] != '-' || name[1] != '-')
		return false;

	for (const unsigned char *p = (const unsigned char *)name + 2; *p; p++) {
		if ((*p >= 'a' && *p <= 'z') ||
		    (*p >= 'A' && *p <= 'Z') ||
		    (*p >= '0' && *p <= '9') ||
		    *p == '-' || *p == '_') {
			continue;
		}
		return false;
	}

	return true;
}

void add_paragraph(const char *text, size_t len) {
	buf_append(&g_html_buf, "<p class=\"para\">");
	render_text(text, len);
	buf_append(&g_html_buf, "</p>");
}

void add_code_block( 
		struct str_view lang,
		struct str_view code) {
	buf_append(&g_html_buf, "<pre style=\"");
	buf_append_attr_escaped(&g_html_buf, code_block_pre, strlen(code_block_pre));
	buf_append(&g_html_buf, "\"><code class=\"language-");
	buf_append_attr_escaped(&g_html_buf, lang.data, lang.len);
	buf_append(&g_html_buf, "\" style=\"");
	buf_append_attr_escaped(&g_html_buf, code_block_code, strlen(code_block_code));
	buf_append(&g_html_buf, "\">");
	buf_escape(&g_html_buf, code.data, code.len);
	buf_append(&g_html_buf, "</code></pre>");
}

void add_image(const char *path, size_t path_len, const char *alt, size_t alt_len, float scale, int width, int height, int is_lcp) {
	buf_append(&g_html_buf, "<p class=\"para\"><span class=\"img-placeholder\" data-src=\"");
	buf_append_attr_escaped(&g_html_buf, path, path_len);
	buf_append(&g_html_buf, "\" data-alt=\"");
	if (alt && alt_len) {
		buf_append_attr_escaped(&g_html_buf, alt, alt_len);
	}
	buf_append(&g_html_buf, "\"");

	if (is_lcp) buf_append(&g_html_buf, " data-lcp=\"1\"");
	if (width > 0) buf_printf(&g_html_buf, " data-width=\"%d\"", width);
	if (height > 0) buf_printf(&g_html_buf, " data-height=\"%d\"", height);
	if (scale > 0 && scale != 1.0f) buf_printf(&g_html_buf, " data-scale=\"%f\"", scale);

	buf_append(&g_html_buf, "></span></p>");
}

void add_blog_entry(const char *title, const char *date, const char *slug) {
	buf_append(&g_html_buf, "<div style=\"margin-bottom:20px;display:flex;gap:20px;\">");
	buf_append(&g_html_buf, "<span style=\"color:var(--dim-text-color);min-width:100px;\">");
	buf_escape(&g_html_buf, date, strlen(date));
	buf_append(&g_html_buf, "</span>");
	buf_append(&g_html_buf, "<a href=\"#/post/");
	buf_append_attr_escaped(&g_html_buf, slug, strlen(slug));
	buf_append(&g_html_buf, "\" style=\"color:var(--text-color);text-decoration:none;\">");
	buf_escape(&g_html_buf, title, strlen(title));
	buf_append(&g_html_buf, "</a></div>");
}

void add_bar(int h, int w, const float *pcts, const char **colors, const float *opacities, const int *styles, int n) {
	buf_printf(&g_html_buf, "<div style=\"width:%dpx;height:%dpx;border:1px solid var(--text-color);display:flex;flex-direction:column;\">", w, h);
	for (int i = 0; i < n; i++) {
		if (!is_safe_css_var_name(colors[i]))
			continue;

		buf_printf(&g_html_buf, "<div style=\"height:%.1f%%;opacity:%.2f;", pcts[i] * 100.0f, opacities[i]);
		if (styles[i] == BAR_SEG_HATCHED) {
			buf_append(&g_html_buf, "background-image:repeating-linear-gradient(45deg,transparent,transparent 2px,var(");
			buf_append(&g_html_buf, colors[i]);
			buf_append(&g_html_buf, ") 2px,var(");
			buf_append(&g_html_buf, colors[i]);
			buf_append(&g_html_buf, ") 3px);");
		} else {
			buf_append(&g_html_buf, "background:var(");
			buf_append(&g_html_buf, colors[i]);
			buf_append(&g_html_buf, ");");
		}
		buf_append(&g_html_buf, "\"></div>");
	}
	buf_append(&g_html_buf, "</div>");
}

void ui_begin_render(void) {
	buf_reset(&g_html_buf);
}

void ui_end_render(void) {
	static const char overflow_html[] =
		"<p class=\"para\">Render buffer exceeded capacity.</p>";
	sys_set_html("#feed", buf_overflowed(&g_html_buf) ? overflow_html : g_html_buf.data);
}

void clear_feed(void) {
	sys_set_html("#feed", "");
}

void add_footer(const char *style, const char *github_url,
		const char *instagram_url) {
	sys_render_footer(style, github_url, instagram_url);
}

void ui_render_header(void) {
    const char *theme_label =
        state.is_dark ? header.light_label : header.dark_label;

    add_header_container(header.container_id, header.container_style);

    add_nav_link(header.title, header.title_style, "nav-title",
             header.container_id, 0);

    const char *group_style = "display:flex;align-items:center;gap:20px;";
    add_nav_group("nav-right-group", header.container_id, group_style);

    add_nav_link(header.home_label, header.item_style, header.home_id,
                 "nav-right-group", 0);
    add_nav_link(header.blog_label, header.item_style, header.blog_id,
                 "nav-right-group", 1);
    add_theme_toggle(theme_label, header.item_style, header.theme_id,
                 "nav-right-group");
}

EM_JS(void, add_nav_group, (const char *id, const char *container_id, const char *style), {
    const parent = document.getElementById(UTF8ToString(container_id));
    if (!parent) return;

    const div = document.createElement('div');
    div.id = UTF8ToString(id);
    div.setAttribute('style', UTF8ToString(style));
    parent.appendChild(div);
});

EMSCRIPTEN_KEEPALIVE
void ui_toggle_theme(void) {
	state.is_dark = !state.is_dark;
	state.theme = state.is_dark ? &theme_dark : &theme_light;
	update_theme_toggle_label(header.theme_id,
				  state.is_dark ? header.light_label :
						  header.dark_label);
	update_theme_colors(state.theme, palette);
	// render_update_strings(header.title, state.theme->text, palette);
	sys_save_theme(state.is_dark ? 1 : 0);
	draw_frame();
}

void ui_init_router(void) { sys_init_router(); }
void ui_sync_url(const char *path) { sys_update_url(path); }
void ui_get_current_hash(char *buf, int max_len) { sys_get_url_hash(buf, max_len); }
void update_seo_metadata(const char *t, const char *d, const char *u) { sys_set_meta(t, d, u); }
