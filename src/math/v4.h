#ifndef V4_H
#define V4_H

#include "v3.h"

typedef struct s_v4
{
	float	x;
	float	y;
	float	z;
	float	w;
}	t_v4;

inline t_v4	v4(float x, float y, float z, float w)
{
	return ((t_v4){x, y, z, w});
}

inline t_v4	v4_from_v3(t_v3 v, float w)
{
	return ((t_v4){v.x, v.y, v.z, w});
}

inline t_v4 v4_scale(t_v4 v, float scalar)
{
	return (t_v4){v.x * scalar, v.y * scalar, v.z * scalar, v.w * scalar};
}

#endif
