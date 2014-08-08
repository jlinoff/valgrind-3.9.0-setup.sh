valgrind-3.9.0-setup.sh
=======================

Bash script to build and install valgrind 3.9.0 with memory limits of 128GB, 256GB and 512GB on linux-x86_64.

Valgrind must have fixed memory limits so that it can accurately track the memory allocations of the program under test. On 64 bit architectures it is limited to 64GB. This script will download, modify and build valgrind for larger memory configurations.

Here is an example of how you might download and use it to create a 128GB version.

    $ mkdir -p work/valgrind/3.9.0
    $ cd work/valgrind/3.9.0
    $ wget http://projects.joelinoff.com/valgrind/valgrind-3.9.0-setup.sh
    $ ./valgrind-3.9.0-setup.sh 128 2>&1|tee log # Build a 128GB version
    $ ./rtf/bin/valgrind -h

Here is an example of how you might download and use it to create a 256GB version.

    $ mkdir -p work/valgrind/3.9.0
    $ cd work/valgrind/3.9.0
    $ wget http://projects.joelinoff.com/valgrind/valgrind-3.9.0-setup.sh
    $ ./valgrind-3.9.0-setup.sh 256 2>&1|tee log # Build a 256GB version.
    $ ./rtf/bin/valgrind -h
