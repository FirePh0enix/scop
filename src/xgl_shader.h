#ifndef XGL_SHADER_H
#define XGL_SHADER_H

#include <stdint.h>

#include "math/utils.h"
#include "math/v2.h"
#include "math/v3.h"
#include "math/v4.h"
#include "math/v4.h"

const t_v3 light_direction = {-1, 0, 0};

inline t_v4 xgl_fragment(t_v2 uv, t_v3 n)
{
    (void) uv;

    float brightness = clampf(v3_dot(light_direction, v3_scale(n, -1)), 0.05, 1.0);
    t_v3 color = {1.0, 1.0, 1.0};

    return v4_scale(v4_from_v3(color, 1.0), brightness);
}

#endif
