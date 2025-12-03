# Build Folder for MOM6-COBALT-FEISTY on monkfish

This folder has the specific instructions to build MOM6-COBALT, and by extension, MOM6-COBALT-FEISTY on the monkfish server at UCSD.

Either copy this folder and its contents into the build directory of your MOM6 installation, or make sure the contents of the existing folder match this. Always use the values located [HERE](https://github.com/jbrzensk/CEFI-regional-MOM6-Fish) before using these values.

In general, the environment does not need to be set, the default modules loaded at login are for building MOM6.

The [makefile](./linux-gnu.mk) has specifics for the build on monkfish for production and debugging runs. One can increase the speed by ~10% by adding the **-ffast-math** flag to the FFLASG and CPPFLAGS options.