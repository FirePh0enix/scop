#ifndef V3_H
#define V3_H

#include <stdbool.h>
#include <math.h>

#include "v2.h"
#include "v2i.h"

typedef struct s_v3
{
	float	x;
	float	y;
	float	z;
} __attribute__((aligned(16)))	t_v3;

inline t_v3	v3(float x, float y, float z)
{
	return (t_v3){x, y, z};
}

inline t_v2i	v3_to_v2i(t_v3 v)
{
	return ((t_v2i){round(v.x), round(v.y)});
}

inline t_v2	v3_to_v2(t_v3 v)
{
	return ((t_v2){v.x, v.y});
}

inline t_v3	v3_add(t_v3 a, t_v3 b)
{
	return (v3(a.x + b.x, a.y + b.y, a.z + b.z));
}

inline t_v3	v3_sub(t_v3 a, t_v3 b)
{
	return (v3(a.x - b.x, a.y - b.y, a.z - b.z));
}

inline t_v3	v3_scale(t_v3 v, float scale)
{
	return (v3(v.x * scale, v.y * scale, v.z * scale));
}

inline t_v3	v3_div(t_v3 v, float scale)
{
	return (v3(v.x / scale, v.y / scale, v.z / scale));
}

inline bool v3_is_zero(t_v3 v)
{
	return v.x == 0 && v.y == 0 && v.z == 0;
}

inline t_v3	v3_cross(t_v3 a, t_v3 b)
{
	t_v3	c;

	c.x = a.y * b.z - a.z * b.y;
	c.y = a.z * b.x - a.x * b.z;
	c.z = a.x * b.y - a.y * b.x;
	return (c);
}

inline float	v3_length(t_v3 v)
{
	return (sqrt(v.x * v.x + v.y * v.y + v.z * v.z));
}

inline float	v3_length_squared(t_v3 v)
{
	return (v.x * v.x + v.y * v.y + v.z * v.z);
}

inline t_v3	v3_norm(t_v3 v)
{
	const float	length = v3_length(v);

	return (v3(v.x / length, v.y / length, v.z / length));
}

inline float	v3_dot(t_v3 a, t_v3 b)
{
	return (a.x * b.x + a.y * b.y + a.z * b.z);
}

#endif
