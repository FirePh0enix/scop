/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   utils.h                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: ledelbec <ledelbec@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2024/06/16 12:09:37 by ledelbec          #+#    #+#             */
/*   Updated: 2024/06/16 12:10:43 by ledelbec         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef UTILS_H
# define UTILS_H

# include <math.h>

inline float	max2(float x, float y)
{
	if (x > y)
		return (x);
	return (y);
}

inline float	min2(float x, float y)
{
	if (x < y)
		return (x);
	return (y);
}

inline float	abs2(float f)
{
	if (f < 0)
		return (-f);
	return (f);
}

inline int	mini2(int a, int b)
{
	if (a > b)
		return (b);
	return (a);
}

inline int	maxi2(int a, int b)
{
	if (a > b)
		return (a);
	return (b);
}

inline float	max3f(float a, float b, float c)
{
	return (max2(a, max2(b, c)));
}

inline float	min3f(float a, float b, float c)
{
	return (min2(a, min2(b, c)));
}

inline float	clampf(float f, float min, float max)
{
	return (max2(min, min2(f, max)));
}

inline float	lerpf(float a, float b, float t)
{
	return (a + t * (b - a));
}

inline float	deg2rad(float f)
{
	return (f / 180.0 * M_PI);
}

#endif
