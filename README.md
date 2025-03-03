# scop

The goal of the project is to create a simple `.obj` file viewer using a graphics API of our choice, so I decided to use none and make all 3d calculation from scratch.

## Compiling

The project was made using zig version `0.14.0-dev.3445+6c3cbb0c8`, since the langage is regularly making breaking change it may not work with other versions.

Also the project depends on X11 and will compile only on Linux if you have `libx11` and `libxext` installed.

You can simply build the project with `zig build --release=fast`, creating an executable `zig-out/bin/scop`.

## Running

The program can be ran like this:
```sh
./zig-out/bin/scop <mesh> [texture]
```

or directly using zig like this:
```sh
zig build run -- <mesh> [texture]
```

The first parameter is the path to a 3D model. The second paramter is optional and is the path to a `.tga` to be used as a texture.

A `settings.zon` file is provided to modify some parameters such as the model position, FOV and more. Also some options can be toggled at runtime.
