#ifndef OBJ_H
#define OBJ_H

#include <stdint.h>
#include "math/v2.h"
#include "math/v3.h"

typedef struct
{
    uint32_t v[3];
    uint32_t t[3];
    uint32_t n[3];
} face_t;

typedef struct
{
    uint32_t vertexCount;
    uint32_t texCoordCount;
    uint32_t normalCount;

    t_v3 *vertices;
    t_v2 *textureCoordinates;
    t_v3 *normals;

    uint32_t faceCount;
    face_t *faces;
} mesh_t;

mesh_t	*mesh_load_from_obj(char *filename);

#endif
