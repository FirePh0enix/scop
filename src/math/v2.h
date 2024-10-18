#ifndef V2_H
#define V2_H

#include <math.h>

typedef struct s_v2
{
	float	x;
	float	y;
}	t_v2;

inline t_v2	v2_add(t_v2 a, t_v2 b)
{
	return ((t_v2){a.x + b.x, a.y + b.y});
}

inline t_v2	v2_sub(t_v2 a, t_v2 b)
{
	return ((t_v2){a.x - b.x, a.y - b.y});
}

inline t_v2	v2_scale(t_v2 v, float s)
{
	return ((t_v2){v.x * s, v.y * s});
}

inline t_v2	v2_div(t_v2 v, float f)
{
	return ((t_v2){v.x / f, v.y / f});
}

inline float	v2_length(t_v2 v)
{
	return (sqrtf(v.x * v.x + v.y * v.y));
}

#endif
