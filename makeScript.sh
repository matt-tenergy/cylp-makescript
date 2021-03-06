## disable, to make buildable for CJ
#rm -rf worker-env  # remove stuff from previous attempt
#virtualenv -p /usr/bin/python2.7 ./worker-env
#exit


set -e
set -x

LIB_DIR=$(pwd)/lib/

rm -rf worker-env  # remove stuff from previous attempt
virtualenv -p /usr/bin/python2.7 ./worker-env

. ./worker-env/bin/activate

# list of packages to install
# do it all in one go
# because otherwise pip won't notice clashing dependencies
# e.g. if the first package requires numpy<=1, but second package requires numpy>=2

TARGETS=""

TARGETS="$TARGETS setuptools==1.4"
TARGETS="$TARGETS toolz==0.8.2" # not sure if version specification is necessary
TARGETS="$TARGETS six==1.10.0" # not sure if version specification is necessary
TARGETS="$TARGETS fastcache==1.0.2"  # not sure if version specification is necessary
TARGETS="$TARGETS multiprocess==0.70.5" # not sure if version specification is necessary
TARGETS="$TARGETS numpy==1.12.1" # version specification definitely necessary
SCIPY_WHL=$LIB_DIR/scipy-0.15.0-cp27-cp27mu-linux_x86_64.whl
TARGETS="$TARGETS $SCIPY_WHL"  # version specification definitely necessary

# Install SCS
SCS_WHEEL_F_NAME=scs-1.2.6-cp27-cp27mu-linux_x86_64.whl
TARGETS="$TARGETS $LIB_DIR/$SCS_WHEEL_F_NAME"

#rm -rf scs

# can't install all in one go, because ECOS depends on scipy but hasn't set up dependency right
pip install $TARGETS

TARGETS="$TARGETS ECOS==2.0.3" # 2.0.3 and 2.0.2  and 2.0.1 works
TARGETS="$TARGETS cvxpy==0.4.10"
TARGETS="$TARGETS cvxcanon==0.0.22"

COMPILATION_DIR="./compilation-artefacts"

if [ ! -d "$COMPILATION_DIR" ]; then
    # make the directory if it doesn't exist
    mkdir $COMPILATION_DIR
fi

rm -rf $COMPILATION_DIR/makeStuff
mkdir $COMPILATION_DIR/makeStuff
tar -xzvf $LIB_DIR/Cbc-2.8.5.tar.gz -C $COMPILATION_DIR/makeStuff

#COIN_INSTALL_DIR="$COMPILATION_DIR/makeStuff/Cbc-2.8.5/"
#export COIN_INSTALL_DIR="$COMPILATION_DIR/makeStuff/Cbc-2.8.5/"

#TARGETS="$TARGETS --no-binary :all: cylp==0.2.3.6"
TARGETS="$TARGETS $LIB_DIR/cylp-0.7.4_-cp27-cp27mu-linux_x86_64.whl"
TARGETS="$TARGETS nose"

# so reinstall the version of numpy we want
# because pip forget what we asked for earlier
TARGETS="$TARGETS numpy==1.12.1"

./worker-env/bin/pip install $TARGETS

ENV_BIN_DIR=$(pwd)/worker-env/lib/python2.7/site-packages/lib/

cp $LIB_DIR/Cbc-bins/. $ENV_BIN_DIR -r
cp $LIB_DIR/bin/libopenblas.so.0 $ENV_BIN_DIR/
cp /usr/lib64/liblapack.so.3 $ENV_BIN_DIR/
cp /usr/lib64/libblas.so.3 $ENV_BIN_DIR/
cp /usr/lib64/libgfortran.so.3 $ENV_BIN_DIR/
cp /usr/lib64/libquadmath.so.0 $ENV_BIN_DIR/
#cp /usr/lib64/libClpSolver.so.1 $ENV_BIN_DIR


export LD_LIBRARY_PATH=$(pwd)/worker-env/lib/python2.7/site-packages/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$(pwd)/worker-env/lib64/python2.7/site-packages/lib/:$LD_LIBRARY_PATH

echo 'export LD_LIBRARY_PATH='$(pwd)'/worker-env/lib/python2.7/site-packages/lib/:$LD_LIBRARY_PATH' >> $(pwd)/worker-env/bin/activate
echo 'export LD_LIBRARY_PATH='$(pwd)'/worker-env/lib64/python2.7/site-packages/lib/:$LD_LIBRARY_PATH' >> $(pwd)/worker-env/bin/activate

# delete needless files to save space
# so there's only 1 copy of it
#find ./worker-env/lib/python2.7/site-packages/ -regextype sed -regex ".*so$" -exec strip {} \;
#python $LIB_DIR/flush.py

python -c 'import scipy; print(scipy.__version__)'
python -c 'import scipy; assert(scipy.__version__ == "0.15.0")'
python -c 'import scs'
python -c 'import ecos'
python -c 'import cvxpy'
python -c 'import CVXcanon'
python -c 'import cylp'

nosetests test.py

# save this into the git repo, just to keep things trackable over time
echo 'saving output of pip-list'
./worker-env/bin/pip list --format=columns > pip-list-current.txt
