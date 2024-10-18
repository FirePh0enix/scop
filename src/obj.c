#include "obj.h"
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

static char	*_read_to_string(char *filename)
{
    FILE *fp = fopen(filename, "r");
    fseek(fp, 0, SEEK_END);

    size_t fileSize = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    char *s = malloc(fileSize + 1);
    fread(s, fileSize, 1, fp);
    s[fileSize] = '\0';
    return s;
}

static int	count_words(const char *str, char c)
{
	int	count;
	int	i;

	i = 0;
	count = 0;
	while (str[i])
	{
		if (str[i] == '\0')
			break ;
		count++;
		if (str[i] == c)
			i++;
		while (str[i] && str[i] != c)
			i++;
	}
	return (count);
}

static int	offset_until_sep(const char *str, int index, char c)
{
	int	i;

	i = index;
	while (str[i])
	{
		if (str[i] == c)
			break ;
		i += 1;
	}
	return (i);
}

static void	*error(char **res)
{
	while (*res)
	{
		free(*res);
		res++;
	}
	free(res);
	return (NULL);
}

static char	**ft_split(const char *s, char c)
{
	char			**res;
	size_t			len;
	size_t			i;
	size_t			k;
	const size_t	slen = strlen(s);

	res = calloc(sizeof(char *), (count_words(s, c) + 1));
	if (!res)
		return (NULL);
	len = 0;
	i = 0;
	while (i < slen)
	{
		k = offset_until_sep(s, i, c);
		if (k >= i)
		{
			res[len] = calloc(1, k - i + 1);
			if (!res[len])
				return (error(res));
			memcpy(res[len++], s + i, k - i);
		}
		i = k + 1;
	}
	return (res);
}

/*static void	read_mtl(t_vars *vars, t_mesh *mesh, char **lines, char *filename)
{
	size_t	i;
	char	*mtllib;
	char	buffer[32];
	char	*s;

	i = 0;
	mtllib = NULL;
	mesh->material = NULL;
	while (lines[i])
	{
		if (strlen(lines[i]) > 7 && !strncmp(lines[i], "mtllib ", 7))
		{
			mtllib = lines[i] + 7;
			break ;
		}
		i++;
	}
	if (!mtllib)
		return ;
	s = strrchr(filename, '/');
	if (s)
	{
		s++;
		memcpy(buffer, filename, s - filename);
		memcpy(buffer + (s - filename), mtllib, strlen(mtllib) + 1);
	}
	else
		memcpy(buffer, mtllib, strlen(mtllib) + 1);
	mesh->material = mtl_load_from_file(vars, buffer);
}*/

/*
 * To support quad faces, they must be splitted in two triangle faces during
 * loading. So if a face has 4 vertices, count it as 2 face.
 *
 * TODO It should use a count_words function.
 */
static int	num_of_tri_faces(char *line)
{
	int	spaces;

	spaces = 0;
	while (*line)
	{
		if (*line == ' ')
			spaces++;
		line++;
	}
	if (spaces == 4)
		return 2;
	return 1;
}

static void alloc_arrays(mesh_t *mesh, char **lines)
{
	size_t	i;

	i = 0;
	while (lines[i])
	{
		if (strlen(lines[i]) > 2 && !strncmp(lines[i], "v ", 2))
			mesh->vertexCount++;
		else if (strlen(lines[i]) > 3 && !strncmp(lines[i], "vt ", 3))
			mesh->texCoordCount++;
		else if (strlen(lines[i]) > 3 && !strncmp(lines[i], "vn ", 3))
			mesh->normalCount++;
		else if (strlen(lines[i]) > 2 && !strncmp(lines[i], "f ", 2))
			mesh->faceCount += num_of_tri_faces(lines[i]);
		i++;
	}

	//printf("- vertices = %zu\n", mesh->vertices_count);
	//printf("- faces    = %zu\n", mesh->faces_count);
	//printf("- textures = %zu\n", mesh->textures_count);
	//printf("- normals  = %zu\n", mesh->normals_count);

	mesh->vertices = calloc(sizeof(t_v3), mesh->vertexCount);
    mesh->faces = calloc(sizeof(face_t), mesh->faceCount);

	if (mesh->texCoordCount > 0)
		mesh->textureCoordinates = calloc(sizeof(t_v2), mesh->texCoordCount);
	else
		mesh->textureCoordinates = calloc(1, sizeof(t_v2));
	if (mesh->normals > 0)
		mesh->normals = calloc(sizeof(t_v3), mesh->normalCount);
	else
		mesh->normals = calloc(1, sizeof(t_v3));
}

static void	read_face_nums(char *line, int index, face_t *face)
{
	const size_t	sz = strlen(line);
	char			*sv;
	char			*svt;
	char			*svn;
	size_t			i;

	sv = strtok(line, "/");
	svt = strtok(NULL, "/");
	svn = strtok(NULL, "/");
	if (sv == NULL || sv[0] == '\0')
		face->v[index] = 0;
	else
		face->v[index] = atoi(sv) - 1;
	if (svt == NULL || svt[0] == '\0')
		face->t[index] = 0;
	else
		face->t[index] = atoi(svt) - 1;
	if (svn == NULL || svn[0] == '\0')
		face->n[index] = 0;
	else
		face->n[index] = atoi(svn) - 1;
	i = 0;
	while (i < sz)
	{
		if (line[i] == '\0')
			line[i] = '/';
		i++;
	}
}

static void	read_face(mesh_t *mesh, char *line)
{
	face_t	face;
	char	*s0;
	char	*s1;
	char	*s2;
	char	*s3;

	s0 = strtok(line, " ");
	s1 = strtok(NULL, " ");
	s2 = strtok(NULL, " ");
	s3 = strtok(NULL, " ");
	if (s3 != NULL)
	{
		read_face_nums(s0, 0, &face);
		read_face_nums(s1, 1, &face);
		read_face_nums(s3, 2, &face);
		mesh->faces[mesh->faceCount++] = face;
		read_face_nums(s1, 0, &face);
		read_face_nums(s2, 1, &face);
		read_face_nums(s3, 2, &face);
		mesh->faces[mesh->faceCount++] = face;
	}
	else
	{
		read_face_nums(s0, 0, &face);
		read_face_nums(s1, 1, &face);
		read_face_nums(s2, 2, &face);
		mesh->faces[mesh->faceCount++] = face;
	}
}

static void	read_arrays(mesh_t *mesh, char **lines)
{
	size_t	i;

	mesh->vertexCount = 0;
	mesh->texCoordCount = 0;
	mesh->normalCount = 0;
	mesh->faceCount = 0;
	i = 0;
	while (lines[i])
	{
		if (strlen(lines[i]) > 2 && !strncmp(lines[i], "v ", 2))
		{
			mesh->vertices[mesh->vertexCount++] = v3(
				atof(strtok(lines[i] + 2, " ")),
				atof(strtok(NULL, " ")),
				atof(strtok(NULL, " "))
            );
		}
		else if (strlen(lines[i]) > 3 && !strncmp(lines[i], "vn ", 3))
		{
			mesh->normals[mesh->normalCount++] = v3(
				atof(strtok(lines[i] + 2, " ")),
				atof(strtok(NULL, " ")),
				atof(strtok(NULL, " "))
			);
		}
		else if (strlen(lines[i]) > 3 && !strncmp(lines[i], "vt ", 3))
		{
			mesh->textureCoordinates[mesh->texCoordCount++] = (t_v2){
				atof(strtok(lines[i] + 3, " ")),
				atof(strtok(NULL, " ")),
			};
		}
		else if (strlen(lines[i]) > 2 && !strncmp(lines[i], "f ", 2))
		{
			read_face(mesh, lines[i] + 2);
		}
		i++;
	}
}

mesh_t	*mesh_load_from_obj(char *filename)
{
	mesh_t		*mesh;
	const char	*str = _read_to_string(filename);
	char		**lines;

	mesh = calloc(1, sizeof(mesh_t));
	lines = ft_split(str, '\n');
	alloc_arrays(mesh, lines);
	// read_mtl(vars, mesh, lines, filename);
	read_arrays(mesh, lines);
	return (mesh);
}
