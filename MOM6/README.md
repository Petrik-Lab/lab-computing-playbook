# MOM6 Installation and run on monkfish.ucsd.edu

Monkfish is setup for the MOM6-COBALT-FEISTY model to be built and run with minimal user modifications.
The environment variables, appropriate packages and libraries, are all loaded by default when you login to monkfish.


# Building and Runing MOM6-COBALT (FEISTY): 

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
There are a series of folders here, with build makefile specifics for each system. The monkfish folder should have two files in it: linux-gnu.env and linux-gnu.mk.  The env file has environemnt variables, which is commented out for monkfish. See the file for specifics on rockfish.

The mk file has build instructions specific for monkfish. No changes should be necessary.

The build process is controlled by 'linux-build.bash', which reads the .mk file and sets the build environment. The command to build has the following command line arguments:
- -m the name of the build instruction folder
- -p the prefix of the filenames in the build folder
- -t type of build, can be (debug, repro, prod)
- -f file, can be (mom6sis2,mom6) for the sea-ice inclusion, or just mom6


To build the production (optomized) mom6 with seaice2 model, run the following command from $MOM6DIR/build.
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



---
## Things changed to make COBALT running with FEISTY
    - MOM input file in MOM_override : MAX_FIELDS = 104

## move outputs  
First save the former COBALT output in "COBALT_output/COBALT_no_FEISTY/":
```
yes | cp /project/CEFI-regional-MOM6/exps/OM4.single_column.COBALT/20040101.*.nc /project/rdenechere/COBALT_output/COBALT_no_FEISTY/
```

Then tune COBALT with FEISTY
```
yes | cp /project/rdenechere/COBALT_output/COBALT_FEISTY/*.F90 /project/CEFI-regional-MOM6/src/ocean_BGC/generic_tracers/
```

After running the model save the ouputs, i.e., .nc, in "COBALT_output/COBALT_FEISTY/"
```
yes | cp /project/CEFI-regional-MOM6/exps/OM4.single_column.COBALT/20040101.*.nc /project/rdenechere/COBALT_output/COBALT_FEISTY/
```

## CEFI debug mode first
debug instead of prog 
`./linux-build.bash -m docker -p linux-gnu -t debug -f mom6sis2`


# Some test with CEFI

## Some function and parameters: 
- cobalt_btm : Bottom temperature
- 20040101.ocean_cobalt_fluxes_int.nc : jhploss : predation fluxes from high trophic levels. 
- daily 2D : Contain the biomass of zooplanktons
- ncdump -h 
- ncview 


## Changing time: 
Changed the `input_nml` file under &coupler_nml: days = 0 & month = 12 

### Extra step for changing time

1. Download the original OM4 JRA dataset from [here](https://drive.google.com/file/d/1QLA8a7S_fHWqwsgJLHssO0sRCs37ARxZ). This dataset contains JRA forcing for the entirety of 2004.
```
cd /project/CEFI-regional-MOM6/exps/datasets
wget "https://drive.usercontent.google.com/download?id=1QLA8a7S_fHWqwsgJLHssO0sRCs37ARxZ&export=download&authuser=0" -O OM4_025.JRA.single_column.tar.gz
```
2. Download the COBALTv3 test dataset from [here](https://urldefense.com/v3/__https://gfdl-med.s3.amazonaws.com/OceanBGC_dataset/1d_datasets.tar.gz__;!!Mih3wA!Go8BmwiLS3KDthzWBALgkynXqTpex1An7xcj3rucW1cYpMaXxVEOWIH57Q2ThrVIPFwsiVP5cF1ft5iFXvsjVgyZQA$).

3. Untar files: 
``` 
tar -zxvf OM4_025.JRA.single_column.tar.gz
tar -zxvf 1d_datasets.tar.gz
```
the files should go into the folders ``OM4_025.JRA.single_column`` and ``dataset`` respectively.

4. Replace all the Original OM4.JRA.single_colum's JRA forcing files to the COBALTv3 dataset:
```
yes | cp OM4_025.JRA.single_column_new/*_atmosphericState_OMIP_MRI-JRA55-do-1-4-0_*.nc OM4_025.JRA.si
ngle_column/
```

5. Create symbolic link 
To creat a link to TARGET in the current directory use: ``ln [OPTION]... TARGET``, with `ln` the link function, `-s` the option for symbolic, and `TARGET` of what is linked: 

The current link are visible here: `ll /project/CEFI-regional-MOM6/exps/OM4.single_column.COBALT/INPUT`, however the link is made from the exp directory:
```
cd ../
ln -s datasets/
```
Previous symbolic should be removed to use ln -s; alternativelly we can copy the directory to exp:
```
cp -r /project/CEFI-regional-MOM6/exps/datasets/datasets_1yr_run/ /project/CEFI-regional-MOM6/exps/
```

the link are already created for the directory datasets, an other option is to rename the old dataset: 
```
mv OM4_025.JRA.single_column/ OM4_025.JRA.single_column_old/
mv OceanBGC_dataset/ OceanBGC_dataset_old/
```
then copy the V3 dataset in the dataset folder: 
```
cp -r datasets_1yr_run/OM4_025.JRA.single_column/ datasets/
cp -r datasets_1yr_run/OceanBGC_dataset/ datasets/
rm -rf datasets_1yr_run/
```
then check the link of the INPUT folder: 
```
ll OM4.single_column.COBALT/INPUT/
```

## Creating your own grid: 
See exemple for creating your own grid [here](https://github.com/yichengt900/MOM6_OBGC_examples/blob/main/exps/OM4.single_column/BuildExchangeGrid.csh)


dowload the Fre-NCtools: 
```
cd /project/MOM6_OBGC_examples/
mkdir work 
cd work
git clone https://github.com/NOAA-GFDL/FRE-NCtools.git
cd FRE-NCtools
export FCFLAGS=-I/usr/include
export LIBS=-lnetcdf
autoreconf -i
mkdir build && cd build
../configure --prefix=/project/MOM6_OBGC_examples/work/FRE-NCtools
make
make install
```

`Warning:`

PATH=$PATH:/usr/include/


## New experiment 
```
cd /project/MOM6_OBGC_examples/exps/MOM6SIS2_experiments/MOM6SIS2COBALT.single_column
PATH=$PATH:/usr/lib64/openmpi/bin/
source ../../builds/redhat850/linux-gnu.env  
mpirun -n 1 ../../../builds/build/redhat850-linux-gnu/ocean_ice/prod/MOM6SIS2 |& tee stdout.redhat
```

