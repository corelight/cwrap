Auto wrap C and C++ functions with instrumentation
=========================

[![MIT License](https://img.shields.io/github/license/corelight/cwrap.svg)](./LICENSE)

cwrap is an experimental but working software with system tests to auto wrap C and C++ functions with instrumentation for code comprehension, debugging, & light performance analysis. Supports gcc & Intel.

cwrap auto instrumentation by example
-----------
Clone cwrap, create example `foo.c`, and compile with and without cwrap:
```
$ git clone https://github.com/corelight/cwrap
$ cat << EOF > foo.c
#include <stdio.h>
int r=0;
void baz() { r++; }
void bar() { printf("hello world!\n"); r++; baz(); }
int main(int argc,char **argv) { bar(); return r; }
EOF
$ CC=gcc                  ; $CC -o foo foo.c && ./foo # compile without cwrap
hello world!
$ CC=`pwd`/cwrap/cwrap.pl ; $CC -o foo foo.c && ./foo # compile with    cwrap; default verbosity off
hello world!
$ wc --bytes foo*
37832 foo            <-- the compiled binary
  141 foo.c          <-- the file created above
39155 foo.cwrap.c    <-- auto created file & auto linked
 5882 foo.cwrap.log  <-- auto created cwrap compilation log
 2198 foo.s          <-- auto created assembler file
 3950 foo.s.2.s      <-- auto created munged assembler file
```
Ask cwrap compiled `foo` which C functions and/or C++ function variations are instrumented:
```
$ CWRAP_LOG_SHOW=1 ./foo
C0 + cwrap_log_show() { #1
C0   - func_addr=(nil)
C0   - #1: verbosity 9 for 1 of 1 function variation for cwrap_log_show() from foo.cwrap.c
C0   - #2: verbosity 9 for 1 of 1 function variation for cwrap_log_stats() from foo.cwrap.c
C0   - #3: verbosity 9 for 1 of 1 function variation for cwrap_log_verbosity_set() from foo.cwrap.c
C0   - #4: verbosity 9 for 1 of 1 function variation for cwrap_log_quiet_until() from foo.cwrap.c
C0   - #5: verbosity 9 for 1 of 1 function variation for main() from ld: foo.c
C0   - #6: verbosity 9 for 1 of 1 function variation for baz() from ld: foo.c
C0   - #7: verbosity 9 for 1 of 1 function variation for bar() from ld: foo.c
C0   } // cwrap_log_show()
```
Ask cwrap compiled `foo`  to run with full verbosity with various output line prefixes, and output stats upon exit:
```
$ CWRAP_LOG_STATS=1 CWRAP_LOG_NUM=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_CURT=1 CWRAP_LOG_VERBOSITY_SET=1 ./foo
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}-<keyword>][/...]) _STATS=1 _SHOW=0 _CURT=1 _FILE=0 _NUM=1 _COR_ID=1 _THREAD_ID=1 _STACK_PTR=0 _TIMESTAMP=1 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
#1 T127207 C0 0.000000s + cwrap_log_verbosity_set(verbosity=1) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
#2 T127207 C0 0.000010s   - verbosity 1 set for 7 matches in 7 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
#3 T127207 C0 0.000021s   } // cwrap_log_verbosity_set()
#4 T127207 C0 0.000026s + main() { // #1
hello world!
#5 T127207 C0 0.000028s   + bar() { // #1
#6 T127207 C0 0.000031s     + baz() {} // #1
#7 T127207 C0 0.000036s     } // bar()
#8 T127207 C0 0.000039s   } // main()
#9 T127207 C0 0.000041s + cwrap_log_stats() { // #1 [cwrap_log_stats() ignores verbosity!]
#10 T127207 C0 0.000043s   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
#11 T127207 C0 0.000075s   - 1 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
#12 T127207 C0 0.000089s   - 1 calls to 1 of 1 function variation for main()
#13 T127207 C0 0.000093s   - 1 calls to 1 of 1 function variation for baz()
#14 T127207 C0 0.000096s   - 1 calls to 1 of 1 function variation for bar()
#15 T127207 C0 0.000098s   - 5 calls to 5 of 7 functions instrumented
#16 T127207 C0 0.000101s   } // cwrap_log_stats()
```
Ask cwrap compiled `foo`  to run but ignore verbosity until `bar()` is executed:
```
$ CWRAP_LOG_QUIET_UNTIL=bar CWRAP_LOG_NUM=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_CURT=1 CWRAP_LOG_VERBOSITY_SET=1 ./foo
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}-<keyword>][/...]) _STATS=0 _SHOW=0 _CURT=1 _FILE=0 _NUM=1 _COR_ID=1 _THREAD_ID=1 _STACK_PTR=0 _TIMESTAMP=1 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=bar
#1 T127212 C0 0.000000s + cwrap_log_verbosity_set(verbosity=1) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
#2 T127212 C0 0.000011s   - verbosity 1 set for 7 matches in 7 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
#3 T127212 C0 0.000020s   } // cwrap_log_verbosity_set()
#4 T127212 C0 0.000038s + cwrap_log_quiet_until(name=bar) {} // #1 going quiet until function bar() [cwrap_log_quiet_until() ignores verbosity!]
hello world!
#5 T127212 C0 0.000047s + bar() { // #1
#6 T127212 C0 0.000049s   + baz() {} // #1
#7 T127212 C0 0.000051s   } // bar()
#8 T127212 C0 0.000053s } // main()
```
Ask cwrap compiled `foo`  to run with full verbosity except verbosity for `bar()` disables its output:
```
$ CWRAP_LOG_NUM=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_CURT=0 CWRAP_LOG_VERBOSITY_SET=1/9=function-bar ./foo
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1:9=function-bar (<verbosity>[={file|function}-<keyword>][/...]) _STATS=0 _SHOW=0 _CURT=0 _FILE=0 _NUM=1 _COR_ID=1 _THREAD_ID=1 _STACK_PTR=0 _TIMESTAMP=1 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
#1 T127218 C0 0.000000s + cwrap_log_verbosity_set() { #1
#2 T127218 C0 0.000009s   - verbosity=1:9=function-bar
#3 T127218 C0 0.000017s   - [cwrap_log_verbosity_set() ignores verbosity!]
#4 T127218 C0 0.000025s   - verbosity 1 set for 7 matches in 7 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
#5 T127218 C0 0.000033s   - verbosity 9 set for 1 matches in 7 functions for 14 byte clause '9=function-bar' // type=FUNCTION keyword=bar
#6 T127218 C0 0.000038s   } // cwrap_log_verbosity_set()
hello world!
#7 T127218 C0 0.000042s + main() { #1
#8 T127218 C0 0.000045s   + baz() { #1
#9 T127218 C0 0.000047s     } // baz()
#10 T127218 C0 0.000052s   } // main()
```
cwrap manual instrumentation by example
-----------
Manually add various cwrap macros to `foo.c`, and compile with and without cwrap:
```
$ cat << EOF > foo.c
#include "cwrap/if-no-cwrap.h" // ignore CWRAP_*() macros
#include <stdio.h>
int r=0;
void baz() { CWRAP_APPEND("r=%d",r); r++; CWRAP_DEBUG("more debug: r=%d",r); }
void bar() { CWRAP_PRINTF("hello world!\n"); r++; baz(); }
int main(int argc,char **argv) { CWRAP_PARAMS("argc=%d",argc); bar(); CWRAP_RESULT("%d",r); return r; }
EOF
$ CC=gcc                  ; $CC -o foo foo.c && ./foo # compile without cwrap
hello world!
$ CC=`pwd`/cwrap/cwrap.pl ; $CC -o foo foo.c && ./foo # compile with    cwrap; default verbosity off
hello world!
```
Notice how `CWRAP_PRINTF()` output gets auto indented if running with cwrap verbosity enabled:
```
$ CWRAP_LOG_NUM=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_CURT=1 CWRAP_LOG_VERBOSITY_SET=1 ./foo
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}-<keyword>][/...]) _STATS=0 _SHOW=0 _CURT=1 _FILE=0 _NUM=1 _COR_ID=1 _THREAD_ID=1 _STACK_PTR=0 _TIMESTAMP=1 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
#1 T127544 C0 0.000000s + cwrap_log_verbosity_set(verbosity=1) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
#2 T127544 C0 0.000011s   - verbosity 1 set for 7 matches in 7 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
#3 T127544 C0 0.000027s   } // cwrap_log_verbosity_set()
#4 T127544 C0 0.000033s + main(argc=1) { // #1
#5 T127544 C0 0.000035s   + bar() { // #1
#6 T127544 C0 0.000038s     - hello world!
#7 T127544 C0 0.000042s     + baz() { // #1 r=1
#8 T127544 C0 0.000044s       - more debug: r=2
#9 T127544 C0 0.000052s       } // baz()
#10 T127544 C0 0.000055s     } // bar()
#11 T127544 C0 0.000058s   } = 2 // main()
```
If verbosity only enabled for `main()` then `CWRAP_PRINTF()` 'demoted' to a regular `printf()`:
Note: The run-time per function verbosity applies to cwrap macros as well as auto entry and exit instrumentation.
```
$ CWRAP_LOG_NUM=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_CURT=1 CWRAP_LOG_VERBOSITY_SET=1=function-main ./foo
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1=function-main (<verbosity>[={file|function}-<keyword>][/...]) _STATS=0 _SHOW=0 _CURT=1 _FILE=0 _NUM=1 _COR_ID=1 _THREAD_ID=1 _STACK_PTR=0 _TIMESTAMP=1 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
#1 T127664 C0 0.000000s + cwrap_log_verbosity_set(verbosity=1=function-main) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
#2 T127664 C0 0.000013s   - verbosity 1 set for 1 matches in 7 functions for 15 byte clause '1=function-main' // type=FUNCTION keyword=main
#3 T127664 C0 0.000023s   } // cwrap_log_verbosity_set()
hello world!
#4 T127664 C0 0.000027s + main(argc=1) {} = 2 // #1
```

Environment variables which influence cwrap at run-time
-----------
- `CWRAP_LOG_NUM=1`: Display line count on each output line.
- `CWRAP_LOG_TIMESTAMP=1`: Display elapsed seconds on each output line.
- `CWRAP_LOG_THREAD_ID=1`: Display thread ID on each output line.
- `CWRAP_LOG_COR_ID=1`: Display coroutine ID on each output line.
- `CWRAP_LOG_LIMIT=<limit>`: Only log functions this many times; default 1,000.
- `CWRAP_LOG_STACK_PTR=1`: Display coroutine stack pointer on each output line.
- `CWRAP_LOG_UNWIND=1`: Experimental option for debugging coroutine stack corruption.
- `CWRAP_LOG_ON_VALGRIND`: Experimental option for debugging coroutine stack corruption.
- `CWRAP_LOG_CURT=1`: Allow function entry and exit output lines to be folded together where possible.
- `CWRAP_LOG_FILE=1`: Output to file instead of stdout.
- `CWRAP_LOG_QUIET_UNTIL=<function>`: Ignore verbosity until function has been called.
- `CWRAP_LOG_VERBOSITY_SET=<verbosity>[={file|function}-<keyword>][/...]`: Set function verbosity [1].
- `CWRAP_LOG_SHOW=1`: List all instrumented functions and exit.

[1] Note: `cwrap_log_verbosity_set("<verbosity>[={file|function}-<keyword>][/...]")` works at run-time too.

How to build and test cwrap?
--------------------------

- cwrap is currently one Perl script and does not need 'building' itself.
- The cwrap Perl script has embedded all the cwrap C source code needed to make everything work.
- cwrap comes with some tests here: https://github.com/corelight/cwrap/tree/master/test

How does cwrap work?
-----------
When gcc is normally called to compile or link, cwrap is called instead and sees all the same command line options. cwrap works roughly as follows:

- **At compile-time**: cwrap alters command line options, e.g. add `-finstrument-functions`, & calls 'real' gcc.
- **At compile-time**: Instead of compiling C/C++ directly to object files, cwrap compiles to assembler files.
- **At compile-time**: Once the assembler file is created, cwrap modifies it before assembling it to an object file.
- **At link-time**: cwrap attempts to link but all the struct instances for each instrumented function will be missing.
- **At link-time**: cwrap generates source code for each struct instance on-the-fly & links again successfully.
- **At run-time**: Upon starting, cwrap is the first code executing in the process; before e.g. C++ initialization etc.
- **At run-time**: As the first code executed, cwrap initializes & traces other C/C++ code running prior to `main()`.
- **At run-time**: The user influences cwrap by setting environment variables which are read at initialization time.
- **At exit-time**: cwrap can display statistics, e.g. how many functions were called how many times.

How is cwrap different from the gcc `-finstrument-functions` option?
-----------
"Generate instrumentation calls for entry and exit to functions" says the docs for the gcc [`-finstrument-functions`](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html) option. cwrap uses `-finstrument-functions` under the covers but tries to address the following limitations:

- **Implementation friction**: `-finstrument-functions` is just a gcc command line option and so to instrument an existing C/C++ project you'd have to do quite a bit of work to modify the project build scripts and source code to get anything working. cwrap solves this by pretending to be a replacement for gcc itself. Tell the project to compile with cwrap instead of gcc, and in theory cwrap takes care of the rest, and you don't have to modify any project build script or source code. Often this can be as easy as `CC=cwrap.pl make` which means every time the makefile would have invoked gcc, it's now invoking cwrap instead.

- **Run-time human friendly names**: Once a project has every C/C++ function entry and exit point instrumented via the gcc `-finstrument-functions` option, this means two generic functions will always be called; `__cyg_profile_func_enter()` and `__cyg_profile_func_exit()` which take the unfriendly parameters `void *this_fn` and `void *call_site` which are the "address of the start of the current function" and a pointer to the stack frame. This means if you want to do something as simple inside the generic functions as outputting the function name being entered or exited, then it's going to be a slow and tedious process to use the given function address together with gcc debug info to lookup the function name so that it can be output. cwrap solves this by replacing the one of the generic function call parameters with a pointer to a struct instance which is unique to the instrumented function. The struct instance is already populated with the human friendly name of the function so no run-time searching is necessary to find the function name, and cwrap also works with non-debug builds of the project because cwrap does not use the compiler generated debug info at run-time.

- **Run-time performance**: Let's say each project function is instrumented using the gcc `-finstrument-functions` option which means that the generic entry and exit functions *must* be called regardless of whether of whether output is wanted at run-time or not. The only place to decide whether to output or not is in the generic function itself, and by the time the generic function has been called, much time has been wasted because calling a function is already an expensive operation in the big scheme of things. cwrap solves this by creating a tiny bit of assembler surrounding the call to the generic enter or exit function. The assembler wrapper checks the cwrap verbosity of the individual function against the global cwrap verbosity and skips calling if necessary. So let's say an instrumented project calls 1M functions at run-time but we want to disable output of the functions until some point. Using just the gcc `-finstrument-functions` option then this would result in 1M generic enter and 1M generic leave functions calls, and then compare and jump. Whereas, using cwrap the equivalent would be 2M compare and jump instructions, with no function calls made to the generic functions.

- **Run-time verbosity and/or statistics**: Let's say each project function is instrumented using the gcc `-finstrument-functions` option which means that the generic entry and exit functions only know about the function address and stack. There is no obvious and/or quick way to store context info about the function such as statistics like how many times the function is called, or it's individual verbosity level at run-time. cwrap solves this by associating a struct instance with each unique project function. Function specific data like the run-time verbosity, or the number of function calls, can be stored in the struct instance. This means the output verbosity of individual functions can be changed arbitrarily at start-up time and/or run-time. Or we do things like turn the global verbosity off until a particular function is called, etc.
- **Run-time instrumentation introspection**: The gcc `-finstrument-functions` option leaves the implementation of the generic entry and exit functions up to the user. In particular, it is not known after compiling, e.g. how many functions were instrumented. cwrap solves this by creating special extra cwrap functions which can be used to introspect the instrumented functions. For example, after compilation it's possible to ask the cwrap compiled process to list all the functions instrumented. This has been tested on [Zeek]([https://github.com/zeek/zeek](https://github.com/zeek/zeek)) which has over 100k functions.

- **Run-time human friendly formatting**: The gcc `-finstrument-functions` option leaves the implementation of the generic entry and exit functions up to the user. cwrap solves this by creating a generic function implementation which outputs a representation of the run-time call-tree, but with a variety of options to tweak the output in various human readable friendly ways in addition to basic indentation. You might expect a line of output to be generated for a function entry, and another line of output for function exit, e.g. imagine `foo()` calling `bar()` and bar also outputs an additional line of instrumentation (and yes, this additional line -- although not enter or exit instrumentation -- is also controlled by the individual verbosity of the function at run-time), we might expect five lines, but the additional instrumentation line can be optionally folded into the collapsed `bar()` entry and exit lines, and if the verbosity for `bar()` is disabled then the `foo()` lines can also be auto folded to a single line, and in addition the user can mark these examples up further with human readable parameter and return value info:
```
    + foo() { // #1
      + bar() { // #1
        - misc comment during bar()               <-- bar() comment on own line
        } // bar()
      } // foo()
```
```
    + foo() { // #1
      + bar() {} // #1 misc comment during bar()  <-- bar() 3 lines into 1
      } // foo()
```
```
    + foo() {} // #1                              <-- bar() verbosity too low
```
```
    + foo(param_1=123 param_2=456) {} = 789 // #1 <-- user adds parameter & return value info
```

How is cwrap useful for code comprehension, debugging, and light performance analysis?
-----------

- **Code comprehension**: Let's say you're evaluating a larger code base like [libarchive](https://github.com/libarchive/libarchive) to determine how best to include it in an even larger code base, if at all. There are too many source files to efficiently manually read and comprehend. One technique is to use the debugger and do back-traces from time to time in order to see the function call-trees at run-time to get an idea about how the code base works. But this is also somewhat hit and miss. Another technique is to trace the function calls at run-time using a tool like cwrap. And an older version of cwrap (which only worked on C and not C++) was used for code comprehension of libarchive and is detailed in this [libarchive github issue](https://github.com/libarchive/libarchive/issues/1268).

- **General debugging**: Let's say you have some C/C++ code where the regular debugger is not best suited for debugging, such as multi-threaded or multi-process code, or code using coroutines. In these scenarios it would be useful to have a record of what happened at run-time at precise times, and then debug using that record. Developers generally use the adhoc and time honored `printf()` to achieve similar results. However, developers still grapple with `printf()` implementation related issues such as how to deal with `printf()` statements after debugging is finished (delete them all?), or how to accurately deal with function exit `printf()` statements when functions have multiple exit points (ignore entry and exit points?), or how to deal with handling verbosity (ignore verbosity?) if the developer decides to make the `printf()` instrumentation permanent? cwrap is a `printf()` alternative without the implementation grappling, providing permanent instrumentation useful for debugging for the lifetime of the code base.

- **Debugging failing tests**: Let's say your project has some automated tests but one of the tests fails about 10% of the time; a so-called 'flappy' test. Often the easiest and quickest way to debug is to compare the cwrap output from a good test run to a bad test run. If there is no difference in the output then it means you have to add more cwrap instrumentation until there is a difference. Usually, a quick compare of the output makes it obvious what in the production code and/or test code needs changing. This is often the quickest way to debug and leverages the groomed permanent instrumentation via cwrap.

- **Performance analysis**: Because cwrap can be configured to show a time-stamp on every output line, it's easy to see the time difference between arbitrary function calls anywhere in the run-time call-tree. However, without verbosity control, the cwrap output of larger code bases can be overwhelming. Also, all that output comes at a price, which slows down the execution of the process. In general, the more cwrap output means the process performs slower with the timing becoming less meaningful, and the closer the cwrap output gets to little or no output then the more meaningful the timing becomes and closer to reality. So because cwrap allows accurate dynamic control over verbosity, it's possible to get a good and accurate idea of how fast certain sections of code take. It's also possible to code in run-time paranoia checks which hardly slow down the execution, e.g. time some code but only show instrumentation at run-time as a performance warning if the code to unexpectedly long to execute.

What is not implemented yet?
--------------------------

- Ability to exclude arbitrary functions from being instrumented.
- Ability to instrument one or more shared objects and have their struct instances compatible with each other.

Discussion
----------

Feel free to discuss aspects of cwrap via GitHub here:
https://github.com/corelight/cwrap/issues
