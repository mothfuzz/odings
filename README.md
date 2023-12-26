# ODINGS - Odin Game System

This can be considered a spiritual successor to my other projects, written in Odin because it is a lovely language.

The engine features an auto-batching OpenGL renderer built for high performance and high compatibility - it should run on most major platforms, including the browser via WebGL.

Tested on desktop for both Windows, Linux, and on the web using Firefox.

Gameplay code is written using an actor system, with helper functions provided for discovering and communicating with other actors in the scene, as well as collision detection & spatial queries.

The engine can be considered both 2D and 3D, and includes helper functions for both to work seamlessly and pixel-perfect.

Modding is built-in using dynamically loaded libraries, and mods are provided the exact same API as internal game code - you could even write a whole game *just* using the mod system.
Mods are not cross-platform once compiled, but can be compiled to any platform, just like the engine itself.

Finally, thanks to resource embedding, game developers can opt to build the engine & all game code (minus mods) as a single executable for easy distribution to players.


## How To:
### Build the engine
First, [install Odin](https://odin-lang.org/docs/install/).
Then, building the engine is as easy as running `odin build .` in the directory you downloaded the engine to.
You can then run the produced executable.
Or, even quicker, you can run `odin run .` to build and run directly in one step.

### Add my own game code internally
Simply open up `main.odin` and edit `init`/`tick`/`draw`/`exit`.
`init` and `exit` are run on setup and teardown respectively, `tick` is run at exactly 125fps, and `draw` is run as many times as your GPU allows.

### Develop a mod / write games using the mod system
Create a new package under the mods folder, e.g. `mymod`, and create a package that exports at least one of the `init`/`tick`/`draw`/`exit` functions - they are called the same way in mod code as they are in internal code.

To load mods, the engine has to be built with mods enabled.
In the directory where you downloaded the engine, follow these steps:

First, build the `gamesystem` library separately - `odin build engine/gamesystem -build-mode:shared`

Then, build the engine with mods enabled - `odin build . -define:ENABLE_MODS=true`

In order to load mods, the executable must be able to find the `gamesystem` shared library in the same directory. The engine will still run if it isn't there, but it will not be able to load mods.

Finally, to build an individual mod, cd to the mods directory and run `odin build "name of your mod" -build-mode:shared`

All libraries (.dll on Windows, .so on Mac/Linux) found in the mods folder will then be attempted to be loaded by the engine as mods.

If you change the engine code, you'll have to rebuild `gamesystem` as well as the engine itself.
If you just change your mod, however, you *only* have to rebuild your mod for the changes to take effect.

### Build for the Web
It's as easy as changing the target when building - `oding build . -target:js_wasm32`

This will produce a `.wasm` file. You can then run a local webserver in the engine directory (e.g. `python -m http.server`) and open up `localhost:8000` in your browser.

When shipping a web application, you'll need to host the engine's `.wasm` build, the `index.html` and the `runtime.js`.

Note that web builds do not support mods.
