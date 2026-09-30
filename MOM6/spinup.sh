#!/bin/bash
#
# THIS SCRIPT ALLOWS TO LOOP THE 1D COLUNM RUN OF THE ONLINE 
# COBALT-FEISTY OVER A GIVEN NUMBER OF YEARS <NUM_YEARS>
# WITH A SPECIFIC PARAMETER VALUE FOR NONFMORT.
# 
# CONTACT: REMY DENECHERE <RDENECHERE@UCSD.EDU>
#        : JARED BRZENSKI <JABRZENSKI@UCSD.EDU>
#
#
# RUN THIS SCRIPT FROM THE CEFI/EXPS/OM4 DIRECTORY
#
# REQUIRES ENVIRONMENT VARIABLES:
#
# SAVE_DIR             -> location of the final saved files. 
#
# 
# Example MPI command to run this without this script:
# MPI_COMMAND="mpiexec --cpu-set # --bind-to core --report-bindings -np 1"
#
###############################################################################
MOM6EXEC="./MOM6FEISTY_prod_625"
MPIPROCS=114
LOC_NAME="spinup"
EXP_NAME="initial"
UNIQUE_ID="20251202"
RUNID="${LOC_NAME}_${EXP_NAME}_${UNIQUE_ID}"

HOME_DIR="$PWD"

WORK_DIR="/scratch/Jared/MOM6_spinup_${UNIQUE_ID}"

# FUNCTION TO KILL ALL SPAWNED PROCESSES
cleanup() {
  echo "Terminating all spawned processes..."
  echo "Check the SCRATCH directory for any stray files."
  echo "Killing processes DOES NOT clean up the file system."
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null
  done
  exit 0
}

# EMPTY ARRAY 
pids=()

# Trap Ctrl-C (SIGINT) and call cleanup function
trap cleanup SIGINT

###############################################################################
# CHECK TO SEE IF OTHER ENVIRONMENTAL VARIABLES ARE SET
if [ -z "${SAVE_DIR}" ]; then
    echo "SAVE_DIR not set, exiting"
    exit 1
else
    echo "Found all environmental variables, continuing..."
fi


WORK_DIR="${SCRATCH_DIR}/${RUNID}"
if [ -d "$WORK_DIR" ]; then
    echo "$WORK_DIR" exists 
else
    cd "${SCRATCH_DIR}"
    if [ -d "$RUNID" ]; then
        echo "$RUNID exists."
    else
        echo create "$RUNID"
        mkdir "${RUNID}"
    fi
    cd "${HOME_DIR}"
fi

if [ -d "$WORK_DIR" ]; then
        echo "${WORK_DIR} exists, continuing..."
else
        echo "${WORK_DIR} does not exist, exiting..."
        exit 1
fi

###############################################################################
# COPY EVERYTHING TO THE SCRATCH DIRECTORY
echo "Copying EVERYTHING! to the WORK_DIR"
cp -rf * "${WORK_DIR}"

# MOVE TO WROKING DIRECTORY
cd "${WORK_DIR}"

# MAKE THE RUNS DIRECTORY
if [ -d "${WORK_DIR}/RUNS" ]; then
    echo "RUNS Directory exists."
else
    echo "RUNS Directory does not exist, making it..."
    mkdir RUNS
fi


####################################################
#  RUN THE MODEL 
####################################################

mpiexec -np "${MPIPROCS}" "${MOM6EXEC}" |& tee stdout."${UNIQUE_ID}".env&
pids+=($1)
wait

####################################################
# MOVE THE DATA TO A NEW FOLDER: 
####################################################
FOLDER_SAVE_LOC="RUNS/${LOC_NAME}/${EXP_NAME}"

if [ -d "$FOLDER_SAVE_LOC" ]; then
    echo "$FOLDER_SAVE_LOC" exist 
else
    echo "$FOLDER_SAVE_LOC" does not exist
    cd RUNS
    if [ -d "$LOC_NAME" ]; then # test subfolder EXP_NAME
        echo  create "$EXP_NAME"
        cd "${LOC_NAME}"
        mkdir "${EXP_NAME}"
    else
        echo  create  "$LOC_NAME" and "$EXP_NAME"
        mkdir "${LOC_NAME}"
        cd "${LOC_NAME}"
        mkdir "${EXP_NAME}"
    fi
fi
cd "${WORK_DIR}"

# SAVE YEAR 1!!
YEAR_FOLDER_PATH="$FOLDER_SAVE_LOC/${RUN_ID}_yr_1"
if [ -d "$YEAR_FOLDER_PATH" ]; then
    rm -rf "$YEAR_FOLDER_PATH"/*
else
    mkdir "$YEAR_FOLDER_PATH"
fi

echo "Saving files to specific YEAR_FOLDER_PATH"
yes | cp -i *.nc "$YEAR_FOLDER_PATH"

###############################################################################
# Loop after 1st year: --------------------------------------------------------
## Set up restart in input.nml file and get restart files: 
sed -i "s/input_filename = 'n'/input_filename = 'r'/g" input.nml
yes | cp -i RESTART/*.nc INPUT/

for ((i=2; i<=NUM_YEARS; i++))
do
    # Create a new folder to save the data of that year: 
    YEAR_FOLDER_PATH="$FOLDER_SAVE_LOC/${RUN_ID}_yr_${i}"
if [ -d "$YEAR_FOLDER_PATH" ]; then
        rm -rf "$YEAR_FOLDER_PATH"/*
    else
        mkdir "$YEAR_FOLDER_PATH"/
    fi

    # Run the model and save the outputs in $folder_save_exp
    mpiexec --cpu-set "${CPU_CORE}" --bind-to core --report-bindings -np 1  ./MOM6SIS2 |& tee stdout."${UNIQUE_ID}".env&
    # 
    pids+=($!)
    wait

    echo "Copying files to YEAR_FOLDER_PATH"
    yes | cp -i *.nc "$YEAR_FOLDER_PATH"/

    # get restart files: 
    echo "Copying RESTART files back to INPUT, there is some clobbering!"
    yes | cp -i RESTART/*.nc INPUT/
done

###############################################################################
# End the experiment: ---------------------------------------------------------
## save the restart files of last year for potential resimulation: 
FOLDER_SAVE_RESTART="${RUN_ID}_yr_${NUM_YEARS}_RESTART"

mkdir "$FOLDER_SAVE_RESTART"

echo
echo "Saving RESTART files into FOLDER_SAVE_RESTART"
yes | cp -i RESTART/*.nc "$FOLDER_SAVE_RESTART"/

## set up back to the original configuration
sed -i "s/input_filename = 'r'/input_filename = 'n'/g" input.nml


############################################
# SAVE EVERYTHING IN THE SAVE DIRECTORY
############################################
echo "Copying RUNS folder to SAVE_DIR"
yes | cp -r RUNS/* "$SAVE_DIR"
echo "Copying RESTART to SAVE_DIR"
yes | cp -r "$FOLDER_SAVE_RESTART" "${SAVE_DIR}/${LOC_NAME}"

cd "$HOME_DIR"
# REMOVE WORKING DIRECTORY AND FOLDERS, ETC...
rm -r "$WORK_DIR"

echo "Simulation done!"
