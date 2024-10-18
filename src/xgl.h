#ifndef XGL_H
#define XGL_H

#include <stdint.h>
#include <stddef.h>

#include "math/mat4.h"
#include "math/v2.h"

#include "obj.h"

typedef union
{
	unsigned int		raw;
	struct
	{
		unsigned char	r;
		unsigned char	g;
		unsigned char	b;
		unsigned char	t;
	};
} xgl_color_t;

typedef struct
{
    t_v2 min;
    t_v2 max;
} xgl_rect_t;

typedef struct
{
    int width;
    int height;

    float *depth_buffer;
    uint32_t *color_buffer;

    void *img;

    void *mlx;
    void *win;

    t_mat4 model;
    t_mat4 view;
    t_mat4 proj;

    t_mat4 mvp;
} xgl_context_t;

void xgl_create_context(xgl_context_t *context, void *mlx, void *win, int width, int height);
void xgl_present(xgl_context_t *context);
void xgl_draw(xgl_context_t *context, mesh_t *mesh);

void xgl_clear(xgl_context_t *context);

void xgl_load_model_matrix(xgl_context_t *context, t_mat4 m);
void xgl_load_view_matrix(xgl_context_t *context, t_mat4 m);
void xgl_load_proj_matrix(xgl_context_t *context, t_mat4 m);

#endif
