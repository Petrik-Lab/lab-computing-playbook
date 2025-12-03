# MOM6 Installation and run on monkfish.ucsd.edu

Monkfish is setup for the MOM6-COBALT-FEISTY model to be built and run with minimal user modifications.
The environment variables, appropriate packages and libraries, are all loaded by default when you login to monkfish.


# Building and Running MOM6-COBALT (FEISTY): 

## Getting the MOM6-COBALT model

Get the model and clone all the required dependencies

```
git clone --recurse-submodules https://github.com/jbrzensk/CEFI-regional-MOM6-Fish.git
```

Check to make sure all of the source files are downloaded. "mocsy" is sometimes not downloaded.
```
ls /CEFI-regional-MOM6-Fish/src/ocean_BGC/mocsy
```

## To build the model:
Assuming we have cloned into a directory $MOM6_DIR, navigate to the build directory
```
cd $MOM6DIR/build
```
There are a series of folders here, with build makefile specifics for each system. The monkfish folder should have two files in it: linux-gnu.env and linux-gnu.mk.  The env file has environment variables, which is commented out for monkfish. See the file for specifics on rockfish.

The mk file has build instructions specific for monkfish. No changes should be necessary.

The build process is controlled by 'linux-build.bash', which reads the .mk file and sets the build environment. The command to build has the following command line arguments:
- -m the name of the build instruction folder
- -p the prefix of the filenames in the build folder
- -t type of build, can be (debug, repro, prod)
- -f file, can be (mom6sis2,mom6) for the sea-ice inclusion, or just mom6


To build the production (optimized) mom6 with seaice2 model, run the following command from $MOM6DIR/build.
```
./linux-build.bash -m monkfish -p linux-gnu -t prod -f mom6sis2
```

This command creates a new directory *build*, which has a new structure
```
build/monkfish-linux-gnu/ocean_ice/prod
```
The build/monkfish-linux-gnu/ocean_ice/prod folder has the executable *MOM6SIS2*.


## To run the model: 

To run the one-dimension column model, navigate to the appropriate exps directory and run the executable. We will capture the screen output to a file called stdout.mom6sis2.

```
cd $MOM6DIR/exps/OM4.single_column.COBALT/
../../builds/build/monkfish-linux-gnu/ocean_ice/prod/MOM6SIS2 |& tee stdout.mom6sis2
```

OR, copy the executable to the current directory and run directly

```
cp ../../builds/build/monkfish-linux-gnu/ocean_ice/prod/MOM6SIS2 .
./MOM6SIS2 |& tee stdout.mom6sis2
```

## Output
Output will be *.nc files in the run directory, with filenames starting with the year of the first runs YYYYMMDD.ocean_NAME_VAR.nc

# Changing Runtime Parameters

Many of the parameters and inputs may be changed without rebuilding MOM6. These values are located in the **exps** directory.

There are a handful of files that may be changed to alter the run

| **Filename** | **Description** |
| :------- | -----------: |
| input.nml | Main file, specify location of MOM and SIS inputs, date, dt, runtime |
| field_table | Initial values, and which netCDF file has them. |
| data_table | Forcing, can be values or read from a file |
| diag_table | Output description, grouped into where, when, what file to put in. |
|  | **BELOW MAY BE IN /INPUT DIRECTORY** |
| MOM_input | MOM parameter input file. Generally this is left alone |
| MOM_override | Overrides values in MOM_input. Use this to change parameters |
| SIS_input | Sea ice input parameters. Similar use to MOM_input |
| SIS_override | Sea ice parameter override |
| COBALT_input | COBALT input specifics, see Charlie Stock for specifics |
| COBALT_override | COBALT overrides. use this to change values |
| MOM_layout | layout and mask for domain decomposition  |
| SIS_layout | layout of the processors for the domain ( matches MOM_layout )|


Most basic things like length of run are set in the **input.nml** file. To model a month from July 2010 to August 2010, you change the month and current_date values in **&coupler_nml** in **input_nml**.
```
 &coupler_nml
        months = 1
        days   = 0
        current_date = 2010,7,1,0,0,0
        hours = 0
        minutes = 0
        seconds = 0
        calendar = 'gregorian'
        dt_cpld  = 3600
        dt_atmos = 3600
        do_atmos = .false.
```
