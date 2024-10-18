#include "xgl.h"
#include "math/mat4.h"

#include <math.h>
#include <mlx.h>
#include <stdlib.h>

#include <X11/Xlib.h>
#include <X11/extensions/XShm.h>

typedef struct	s_img
{
	XImage			*image;
	Pixmap			pix;
	GC				gc;
	int				size_line;
	int				bpp;
	int				width;
	int				height;
	int				type;
	int				format;
	char			*data;
	XShmSegmentInfo	shm;
}				t_img;

void xgl_create_context(xgl_context_t *context, void *mlx, void *win, int width, int height)
{
    context->mlx = mlx;
    context->win = win;

    context->width = width;
    context->height = height;

    context->img = mlx_new_image(mlx, width, height);

    context->color_buffer = (uint32_t *)((t_img *) context->img)->data;
    context->depth_buffer = calloc(sizeof(float), width * height);
}

void xgl_present(xgl_context_t *context)
{
    mlx_put_image_to_window(context->mlx, context->win, context->img, 0, 0);
}

void xgl_load_model_matrix(xgl_context_t *context, t_mat4 m)
{
    context->model = m;
    context->mvp = mat4_mul_mat4(mat4_mul_mat4(context->proj, context->view), context->model);
}

void xgl_load_view_matrix(xgl_context_t *context, t_mat4 m)
{
    context->view = m;
    context->mvp = mat4_mul_mat4(mat4_mul_mat4(context->proj, context->view), context->model);
}

void xgl_load_proj_matrix(xgl_context_t *context, t_mat4 m)
{
    context->proj = m;
    context->mvp = mat4_mul_mat4(mat4_mul_mat4(context->proj, context->view), context->model);
}

void	xgl_clear(xgl_context_t *context)
{
	int			i;

	i = 0;
	while (i < context->width * context->height)
	{
		context->depth_buffer[i] = 1.0;
        context->color_buffer[i] = 0x0;
		i++;
	}
}
