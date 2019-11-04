# How to use meta-virtualization-ci

# install dependecies first
$ apt-get install git repo texinfo chrpath makeinfo make

# clone and build meta-virtualization-ci
$ git clone -b <yocto_branch> https://github.com/cevatbostancioglu/meta-virtualization-ci.git
$ cd meta-virtualization-ci/yocto
$ bash build.sh fetch
$ bash build.sh build

these will build all meta-virtualization class.
