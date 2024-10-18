#ifndef V2I_H
# define V2I_H

typedef struct s_v2i
{
	int	x;
	int	y;
}	t_v2i;

static inline	t_v2i	v2i(int x, int y)
{
	return ((t_v2i){x, y});
}

inline t_v2i	v2i_add(t_v2i a, t_v2i b)
{
	return ((t_v2i){a.x + b.x, a.y + b.y});
}

inline t_v2i	v2i_sub(t_v2i a, t_v2i b)
{
	return ((t_v2i){a.x - b.x, a.y - b.y});
}

#endif
