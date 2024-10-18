CC = clang
CFLAGS = -Wall -Wextra -Isrc -Imlx -O3 -g -MMD

NAME = scop

SOURCES=              \
	src/main.c        \
	src/obj.c         \
	src/xgl_context.c \
	src/xgl_draw.c    \
	src/math/mat4.c

OBJECTS=$(SOURCES:.c=.o)
DEPS=$(SOURCES:.c=.d)

MLX=mlx/libmlx.a

all: $(NAME)

-include $(DEPS)

$(NAME): $(OBJECTS) $(MLX)
	$(CC) -o $(NAME) $(OBJECTS) $(CFLAGS) $(MLX) -lm -lX11 -lXext

perf: CFLAGS+=-pg
perf: all
	./scop
	gprof scop gmon.out > profile.txt

$(MLX):
	make -C mlx

clean:
	rm -f $(OBJECTS) $(DEPS) $(NAME)
