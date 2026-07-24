#include "pages.h"

#include "assets.h"
#include "config.h"
#include "ui.h"

#include <stddef.h>
#include <string.h>

void page_render_home(void) {
	const char *pfp = ASSET_PFP;

	add_image(pfp, strlen(pfp), NULL, 0, 1.0f, 393, 458, 1);
	add_paragraph(msg_whoami, strlen(msg_whoami));
	add_paragraph(msg_bio, strlen(msg_bio));

	update_seo_metadata("Bonatto - Home", msg_seo, "#/");
}

void page_render_blog(void) {
	const char *header = "Blog Index";
	int i;

	add_paragraph(header, strlen(header));
	for (i = 0; i < posts_count; i++) {
		add_blog_entry(posts[i].title, posts[i].date, posts[i].slug);
	}

	update_seo_metadata("Bonatto - Blog",
			    "Blog archive and articles about formal methods, "
			    "programming languages, and systems.",
			    "#/blog");
}

void page_render_404(void) {
	add_paragraph(msg_404_title, strlen(msg_404_title));
	add_paragraph(msg_404_body, strlen(msg_404_body));

	update_seo_metadata("Bonatto - 404", msg_404_body, "#/404");
}

void page_add_footer(void) {
	add_footer(css_footer, msg_github_url);
}
