#include <stdbool.h>

#include <mlx.h>
#include <X11/Xlib.h>

#include "xgl.h"
#include "math/mat4.h"
#include "obj.h"

typedef struct
{
    void *mlx;
    void *win;

    xgl_context_t context;
    mesh_t *mesh;

    float rot_y;
} scop_t;

static void destroy_hook(scop_t *scop)
{
    mlx_loop_end(scop->mlx);
}

static void loop_hook(scop_t *scop)
{
    t_mat4 model = mat4_model(v3(0, -2, -7), v3(deg2rad(45), scop->rot_y, 0));
    xgl_load_model_matrix(&scop->context, model);

    scop->rot_y += deg2rad(1.0);

    xgl_clear(&scop->context);
    xgl_draw(&scop->context, scop->mesh);
    xgl_present(&scop->context);
}

int main()
{
    scop_t scop;

    scop.mlx = mlx_init();
    scop.win = mlx_new_window(scop.mlx, 1280, 720, "scop");
    xgl_create_context(&scop.context, scop.mlx, scop.win, 1280, 720);

    scop.rot_y = 0.0;

    t_mat4 view = mat4_translation(v3(0, 0, 0));
    t_mat4 proj = mat4_projection(70.0, 1280, 720, 0.01, 1000.0);

    xgl_load_view_matrix(&scop.context, view);
    xgl_load_proj_matrix(&scop.context, proj);

    scop.mesh = mesh_load_from_obj("teapot.obj");

    mlx_hook(scop.win, DestroyNotify, 0, (void *) destroy_hook, &scop);
    mlx_loop_hook(scop.mlx, (void *) loop_hook, &scop);
    mlx_loop(scop.mlx);
}
