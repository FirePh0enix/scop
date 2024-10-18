#include "math/mat4.h"
#include "xgl.h"
#include "xgl_shader.h"
#include "math/v3.h"
#include "math/utils.h"

#include <stdio.h>

/*
 * Reference:
 * http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html#algo1
 * https://www.youtube.com/watch?v=k5wtuKWmV48
 */

inline float	edge_fn(t_v3 a, t_v3 b, t_v3 c)
{
	return ((a.x - c.x) * (b.y - c.y) - (a.y - c.y) * (b.x - c.x));
}

/*
 * Two steps are necessary to correctly interpolate a value:
 * - Divide every values by their associated z vertex component.
 * - Compute the interpolate value.
 */

inline void	pint_v3(t_v3 *v0, t_v3 *v1, t_v3 *v2, float z0, float z1, float z2)
{
	v0->x /= z0;
	v0->y /= z0;
	v1->x /= z1;
	v1->y /= z1;
	v2->x /= z2;
	v2->y /= z2;
}

inline t_v3	int_v3(t_v3 v0, t_v3 v1, t_v3 v2, t_v3 w, float z)
{
	return (v3(
		(w.x * v0.x + w.y * v1.x + w.z * v2.x) * z,
		(w.x * v0.y + w.y * v1.y + w.z * v2.y) * z,
		(w.x * v0.z + w.y * v1.z + w.z * v2.z) * z
	));
}

inline void	pint_v2(t_v2 *v0, t_v2 *v1, t_v2 *v2, float z0, float z1, float z2)
{
	v0->x /= z0;
	v0->y /= z0;
	v1->x /= z1;
	v1->y /= z1;
	v2->x /= z2;
	v2->y /= z2;
}

inline t_v2	int_v2(t_v2 v0, t_v2 v1, t_v2 v2, t_v3 w, float z)
{
	return ((t_v2){
		(w.x * v0.x + w.y * v1.x + w.z * v2.x) * z,
		(w.x * v0.y + w.y * v1.y + w.z * v2.y) * z,
	});
}

inline void	pint_v1(float *v0, float *v1, float *v2, float z0, float z1, float z2)
{
	*v0 /= z0;
	*v1 /= z1;
	*v2 /= z2;
}

inline float	int_v1(float v0, float v1, float v2, t_v3 w, float z)
{
	return ((w.x * v0 + w.y * v1 + w.z * v2) * z);
}

static void _xgl_draw_triangle(
    xgl_context_t *context,
    t_v3 v0, t_v3 v1, t_v3 v2,
    t_v2 t0, t_v2 t1, t_v2 t2,
    t_v3 n0, t_v3 n1, t_v3 n2
)
{
    t_v2 size = {context->width, context->height};

    n0 = mat4_multiply_v3(context->model, n0);
    n1 = mat4_multiply_v3(context->model, n1);
    n2 = mat4_multiply_v3(context->model, n2);

	// FIXME:
	// This fix the depth buffer bug. There is still a performance hit when the camera enters a mesh.
	if (v0.z < 0.1 || v1.z < 0.1 || v2.z < 0.1)
	{
		return ;
	}

	// Convert from screen space to NDC then raster (in one go)
	v0.x = (1 + v0.x) * 0.5 * size.x, v0.y = (1 + v0.y) * 0.5 * size.y;
	v1.x = (1 + v1.x) * 0.5 * size.x, v1.y = (1 + v1.y) * 0.5 * size.y;
	v2.x = (1 + v2.x) * 0.5 * size.x, v2.y = (1 + v2.y) * 0.5 * size.y;

	int	min_x, max_x, min_y, max_y;

	min_x = min3f(v0.x, v1.x, v2.x);
	max_x = max3f(v0.x, v1.x, v2.x);
	min_y = min3f(v0.y, v1.y, v2.y);
	max_y = max3f(v0.y, v1.y, v2.y);

	// The triangle is outside of the screen.
	// TODO This check could probably be sooner. (maybe before NDC to screen space)
	if (min_x >= size.x || min_y >= size.y || max_x < 0 || max_y < 0)
		return ;

	min_x = fmaxf(min_x, 0);
	min_y = fmaxf(min_y, 0);
	max_x = fminf(max_x, size.x - 1);
	max_y = fminf(max_y, size.y - 1);

	pint_v2(&t0, &t1, &t2, v0.z, v1.z, v2.z);
	pint_v3(&n0, &n1, &n2, v0.z, v1.z, v2.z);
	v0.z = 1 / v0.z, v1.z = 1 / v1.z, v2.z = 1 / v2.z;

	float area = edge_fn(v0, v1, v2);

	for (int j = min_y; j <= max_y; ++j)
	{
		for (int i = min_x; i <= max_x; ++i)
		{
			t_v3 p = {i + 0.5f, j + 0.5f, 0.0};
			float w0 = edge_fn(v1, v2, p);
			float w1 = edge_fn(v2, v0, p);
			float w2 = edge_fn(v0, v1, p);

			if (w0 >= 0 && w1 >= 0 && w2 >= 0)
			{
				w0 /= area, w1 /= area, w2 /= area;

				float	z = (w0 * v0.z + w1 * v1.z + w2 * v2.z);
				float	one_z = 1 / z;
				t_v3	w = v3(w0, w1, w2);
				t_v2	uv = int_v2(t0, t1, t2, w, one_z);
				t_v3	n = int_v3(n0, n1, n2, w, one_z);

				size_t	index = i + (size.y - j - 1) * size.x;

                float inv_z = 1.0 - z;

				// FIXME: When camera is near the mesh, fps drops
				// if (z < context->depth_buffer[index] || z < 0.0 || z > 1.0)
				if (inv_z > context->depth_buffer[index])
					continue ;

                // printf("%f\n", z);

                t_v4 pixelf = xgl_fragment(uv, n);
                
                xgl_color_t color;
                color.r = pixelf.x * 0xFF;
                color.g = pixelf.y * 0xFF;
                color.b = pixelf.z * 0xFF;
                color.t = (1.0 - pixelf.w) * 0xFF;

                context->color_buffer[index] = color.raw;
                context->depth_buffer[index] = inv_z;
			}
		}
	}
}

void xgl_draw(xgl_context_t *context, mesh_t *mesh)
{
    for (size_t i = 0; i < mesh->faceCount; i++)
    {
        face_t face = mesh->faces[i];

        t_v3 v0 = mesh->vertices[face.v[0]];
        t_v3 v1 = mesh->vertices[face.v[1]];
        t_v3 v2 = mesh->vertices[face.v[2]];

        t_v2 t0 = mesh->textureCoordinates[face.t[0]];
        t_v2 t1 = mesh->textureCoordinates[face.t[1]];
        t_v2 t2 = mesh->textureCoordinates[face.t[2]];

        t_v3 n0 = mesh->normals[face.n[0]];
        t_v3 n1 = mesh->normals[face.n[1]];
        t_v3 n2 = mesh->normals[face.n[2]];

        if (mesh->normalCount == 0)
        {
            n0 = v3_norm(v0);
            n1 = v3_norm(v1);
            n2 = v3_norm(v2);
        }

        v0 = mat4_multiply_v3(context->mvp, v0);
        v1 = mat4_multiply_v3(context->mvp, v1);
        v2 = mat4_multiply_v3(context->mvp, v2);

        t_v3 edge1 = v3_norm(v3_sub(v1, v0));
        t_v3 edge2 = v3_norm(v3_sub(v2, v1));
        t_v3 face_normal = v3_cross(edge1, edge2);

        if (v3_dot(face_normal, v3(0, 0, 1)) < 0)
        {
            continue;
        }

        // TODO: Should be done outside the loop right after loading the model.

        _xgl_draw_triangle(context, v0, v1, v2, t0, t1, t2, n0, n1, n2);
    }
}
