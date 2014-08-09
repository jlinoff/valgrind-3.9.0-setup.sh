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

Here is a description of how you might use it on an example program.

Step 1. Compile and link the program

In this very simple example I am using debug compile flags with extensions that provide more information in valgrind. These compile flags must be used with a newer GNU compiler like 4.7.2. I am using 4.9.1 for this example.

    $ RTFDIR="/opt/gcc/4.9.1"  # g++ 4.9.1 compiler (local installation)
    $ export PATH="$RTFDIR/bin:${PATH}"
    $ export LD_LIBRARY_PATH="$RTFDIR/lib64:$RTFDIR/lib:${LD_LIBRARY_PATH}"
    $ cat test.cc
    #include <vector>
    #include <string>
    #include <iostream>
    #include <iomanip>
    using namespace std;
     
    void sub1()
    {
      vector<string> strs;
      for(int i=1; i<10; i++) {
        char buf[79];
        for(unsigned i=0; i<sizeof(buf); i++) {
          buf[i] = '0' + i;
        }
        buf[sizeof(buf)-1] = 0;
        strs.push_back(buf);
      }
      unsigned i=0;
      for(auto str : strs) {
        cout << right << setw(4) << ++i << " "
             << str.size()
             << "\"" << str << "\" "
             << endl;
      }
    }
    
    int main()
    {
      cout << "test" << endl;
      sub1();
      cout << "done" << endl;
      return 0;
    }
    $ g++ --version
    g++ (GCC) 4.9.1
    Copyright (C) 2014 Free Software Foundation, Inc.
    This is free software; see the source for copying conditions.  There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
     
    $ g++ -DDEBUG \
        -std=c++11 \
        -Wall \
        -g3 \
        -gno-strict-dwarf \
        -gdwarf-3 \
        -fvar-tracking \
        --param max-vartrack-size=0 \
        --param max-vartrack-expr-depth=50 \
        -o ./test.exe \
        test.cc
    $ ./test.exe
    test
       1 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       2 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       3 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       4 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       5 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       6 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       7 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       8 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
       9 78"0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}"
    done

Step 2. Run valgrind

This is how you might run valgrind. It includes a suppression file just to show how it works.

    $ cat test.supp
    # This is an example suppression.
    # It is not needed for this example.
    {
       ipp-suppress-conditional-jump1
       Memcheck:Cond
       fun:index
       fun:expand_dynamic_string_token
       fun:_dl_map_object
       fun:map_doit
    }
    $ ~/work/valgrind/3.9.0/rtf/bin/valgrind --version
    valgrind-3.9.0
    $ RTFDIR="/opt/gcc/4.9.1"  # g++ 4.9.1 compiler (local installation)
    $ export PATH="$RTFDIR/bin:${PATH}"
    $ export LD_LIBRARY_PATH="$RTFDIR/lib64:$RTFDIR/lib:${LD_LIBRARY_PATH}"
    $ ~/work/valgrind/3.9.0/rtf/bin/valgrind \
        --tool=memcheck \
        --error-limit=no \
        --free-fill=0xcd \
        --keep-stacktraces=alloc-and-free \
        --leak-check=full \
        --leak-resolution=med \
        --main-stacksize=16777216 \
        --malloc-fill=0xab \
        --max-stackframe=4194304 \
        --num-callers=50 \
        --read-var-info=yes \
        --show-reachable=yes \
        --suppressions=./test.supp \
        --trace-children=yes \
        --track-origins=yes \
        -v \
        ./test.exe
    ==23754== Memcheck, a memory error detector
    ==23754== Copyright (C) 2002-2013, and GNU GPL'd, by Julian Seward et al.
    ==23754== Using Valgrind-3.9.0 and LibVEX; rerun with -h for copyright info
    ==23754== Command: ./test.exe
    ==23754==
    --23754-- Valgrind options:
    .
    .
