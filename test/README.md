Test cwrap
=========================

How to describe the test strategy?
-----------

- There is a simple and generic group of source files used to build a C and C++ project:
```
$ wc --lines c*.[ch]*
   2 c---example-1.a.c
   1 c---example-1.b.c
  66 cpp-example-1.a.cpp
   8 cpp-example-1.a.hpp
   8 cpp-example-1.b.cpp
  11 cpp-example-1.b.hpp
```

- There are simple makefiles to build each project:
```
$ wc --lines *.mak
   9 c---example-1.via-1-line.mak
  18 c---example-1.via-n-line.mak
   9 cpp-example-1.via-1-line.mak
  18 cpp-example-1.via-n-line.mak
```

- Each project is built a number of times and compared with the relevant cwrap output for success:
```
$ wc --lines *.txt
  120 c---example-1.exclude-----.output.txt
   93 c---example-1.include-curt.output.txt
  177 c---example-1.include-long.output.txt
  201 cpp-example-1.exclude-----.output.txt
  153 cpp-example-1.include-curt.output.txt
  299 cpp-example-1.include-long.output.txt
```

- A Perl script generates an uber test makefile which can simultaneously run the following build combinations:
  - Build C or C++ project.
  - Build with or without the curt (read: auto 'folds' instrumentation) or long cwrap output.
  - Build with a single gcc command to compile and link, or multiple gcc commands.
  - Build with particular gcc optimization, i.e.  `-O0`, `-O1`, `-O2`, and `-O3`.
  - Build without cwrap instrumentation.

How to run the tests?
-----------

* Run the tests inside the test folder as follows:
```
$ time perl cwrap-test.pl
- test: strategy: build common source code in all combinations of C / C++, without / with curt / with long cwrap, few / many gcc commands, O0 / 1 / 2 / 3 gcc optimization
- test: wiping folder: build/
- test: running: cd build ; make -j 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-1-line-opt-O0 ; (time make -f c---example-1.via-1-line.mak OPT="-O0") > build.log 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-1-line-opt-O1 ; (time make -f c---example-1.via-1-line.mak OPT="-O1") > build.log 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-1-line-opt-O2 ; (time make -f c---example-1.via-1-line.mak OPT="-O2") > build.log 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-1-line-opt-O3 ; (time make -f c---example-1.via-1-line.mak OPT="-O3") > build.log 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-n-line-opt-O0 ; (time make -f c---example-1.via-n-line.mak OPT="-O0") > build.log 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-n-line-opt-O1 ; (time make -f c---example-1.via-n-line.mak OPT="-O1") > build.log 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-n-line-opt-O2 ; (time make -f c---example-1.via-n-line.mak OPT="-O2") > build.log 2>&1
> cd language-c---example-1-cwrap-exclude------make-via-n-line-opt-O3 ; (time make -f c---example-1.via-n-line.mak OPT="-O3") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O0 ; (time make -f c---example-1.via-1-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O1 ; (time make -f c---example-1.via-1-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O2 ; (time make -f c---example-1.via-1-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O3 ; (time make -f c---example-1.via-1-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O0 ; (time make -f c---example-1.via-n-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O1 ; (time make -f c---example-1.via-n-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O2 ; (time make -f c---example-1.via-n-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O3 ; (time make -f c---example-1.via-n-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-1-line-opt-O0 ; (time make -f c---example-1.via-1-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-1-line-opt-O1 ; (time make -f c---example-1.via-1-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-1-line-opt-O2 ; (time make -f c---example-1.via-1-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-1-line-opt-O3 ; (time make -f c---example-1.via-1-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-n-line-opt-O0 ; (time make -f c---example-1.via-n-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-n-line-opt-O1 ; (time make -f c---example-1.via-n-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-n-line-opt-O2 ; (time make -f c---example-1.via-n-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-c---example-1-cwrap-include-long-make-via-n-line-opt-O3 ; (time make -f c---example-1.via-n-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O0 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O1 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O2 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O2") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O3 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O3") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O0 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O1 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O2 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O2") > build.log 2>&1
> cd language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O3 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O3") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O0 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O1 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O2 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O3 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O0 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O1 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O2 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O3 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=1") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O0 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O1 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O2 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O3 ; (time make -f cpp-example-1.via-1-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O0 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O0" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O1 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O1" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O2 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O2" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
> cd language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3 ; (time make -f cpp-example-1.via-n-line.mak OPT="-O3" CC="perl ../../../cwrap.pl -DCWRAP_LOG_CURT=0") > build.log 2>&1
ok 1 - test: build/language-c---example-1-cwrap-exclude------make-via-1-line-opt-O0
ok 2 - test: build/language-c---example-1-cwrap-exclude------make-via-1-line-opt-O1
ok 3 - test: build/language-c---example-1-cwrap-exclude------make-via-1-line-opt-O2
ok 4 - test: build/language-c---example-1-cwrap-exclude------make-via-1-line-opt-O3
ok 5 - test: build/language-c---example-1-cwrap-exclude------make-via-n-line-opt-O0
ok 6 - test: build/language-c---example-1-cwrap-exclude------make-via-n-line-opt-O1
ok 7 - test: build/language-c---example-1-cwrap-exclude------make-via-n-line-opt-O2
ok 8 - test: build/language-c---example-1-cwrap-exclude------make-via-n-line-opt-O3
ok 9 - test: build/language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O0
ok 10 - test: build/language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O1
ok 11 - test: build/language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O2
ok 12 - test: build/language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O3
ok 13 - test: build/language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O0
ok 14 - test: build/language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O1
ok 15 - test: build/language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O2
ok 16 - test: build/language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O3
ok 17 - test: build/language-c---example-1-cwrap-include-long-make-via-1-line-opt-O0
ok 18 - test: build/language-c---example-1-cwrap-include-long-make-via-1-line-opt-O1
ok 19 - test: build/language-c---example-1-cwrap-include-long-make-via-1-line-opt-O2
ok 20 - test: build/language-c---example-1-cwrap-include-long-make-via-1-line-opt-O3
ok 21 - test: build/language-c---example-1-cwrap-include-long-make-via-n-line-opt-O0
ok 22 - test: build/language-c---example-1-cwrap-include-long-make-via-n-line-opt-O1
ok 23 - test: build/language-c---example-1-cwrap-include-long-make-via-n-line-opt-O2
ok 24 - test: build/language-c---example-1-cwrap-include-long-make-via-n-line-opt-O3
ok 25 - test: build/language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O0
ok 26 - test: build/language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O1
ok 27 - test: build/language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O2
ok 28 - test: build/language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O3
ok 29 - test: build/language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O0
ok 30 - test: build/language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O1
ok 31 - test: build/language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O2
ok 32 - test: build/language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O3
ok 33 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O0
ok 34 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O1
ok 35 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O2
ok 36 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O3
ok 37 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O0
ok 38 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O1
ok 39 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O2
ok 40 - test: build/language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O3
ok 41 - test: build/language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O0
ok 42 - test: build/language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O1
ok 43 - test: build/language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O2
ok 44 - test: build/language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O3
ok 45 - test: build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O0
ok 46 - test: build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O1
ok 47 - test: build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O2
ok 48 - test: build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3
ok 49 - test: as expected, at least one build has 'movq cwrap_data_.*, %rxx' where rxx is not rdi
ok 50 - test: compressed 100 bytes unique demangled name to expected 23 bytes non-unique name: (&std::forward<>()) [9]
ok 51 - test: compressed 109 bytes unique demangled name to expected 58 bytes non-unique name: caf::data_processor<>::apply()::{unnamed-type}::operator()
ok 52 - test: compressed 130 bytes unique demangled name to expected 32 bytes non-unique name: (*std::_Any_data::_M_access<>())
ok 53 - test: compressed 138 bytes unique demangled name to expected 13 bytes non-unique name: delete_each<>
ok 54 - test: compressed 175 bytes unique demangled name to expected 37 bytes non-unique name: caf::detail::tuple_inspect_delegate<>
ok 55 - test: compressed 178 bytes unique demangled name to expected 19 bytes non-unique name: (&std::forward<>())
ok 56 - test: compressed 299 bytes unique demangled name to expected 41 bytes non-unique name: caf::(anonymous-namespace)::fill_builtins
ok 57 - test: compressed 490 bytes unique demangled name to expected 70 bytes non-unique name: broker::core_actor()::{lambda()}::operator()()::{lambda()}::operator()
ok 58 - test: compressed 573 bytes unique demangled name to expected 60 bytes non-unique name: broker::detail::network_cache::fetch<>()::{lambda()}::~fetch
ok 59 - test: compressed 773 bytes unique demangled name to expected 16 bytes non-unique name: std::transform<>
ok 60 - test: compressed 1542 bytes unique demangled name to expected 42 bytes non-unique name: std::caf::default_sum_type_access<>::get<>
ok 61 - test: compressed 1944 bytes unique demangled name to expected 23 bytes non-unique name: std::forward_as_tuple<>
ok 62 - test: compressed 6200 bytes unique demangled name to expected 136 bytes non-unique name: caf::io::middleman::remote_group()::{lambda()}::operator()()::{lambda()}::operator()()::{lambda()}::operator()()::{lambda()}::operator()
ok 63 - test: compressed 6793 bytes unique demangled name to expected 33 bytes non-unique name: std::_Tuple_impl<>::_Tuple_impl<>
1..63

real    0m2.652s
user    0m24.073s
sys     0m6.775s
```


How to examine the tests further?
-----------

* One folder per build combination is created in the `build/` folder together with the uber makefile:
```
$ ls -1 build/
language-c---example-1-cwrap-exclude------make-via-1-line-opt-O0
language-c---example-1-cwrap-exclude------make-via-1-line-opt-O1
language-c---example-1-cwrap-exclude------make-via-1-line-opt-O2
language-c---example-1-cwrap-exclude------make-via-1-line-opt-O3
language-c---example-1-cwrap-exclude------make-via-n-line-opt-O0
language-c---example-1-cwrap-exclude------make-via-n-line-opt-O1
language-c---example-1-cwrap-exclude------make-via-n-line-opt-O2
language-c---example-1-cwrap-exclude------make-via-n-line-opt-O3
language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O0
language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O1
language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O2
language-c---example-1-cwrap-include-curt-make-via-1-line-opt-O3
language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O0
language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O1
language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O2
language-c---example-1-cwrap-include-curt-make-via-n-line-opt-O3
language-c---example-1-cwrap-include-long-make-via-1-line-opt-O0
language-c---example-1-cwrap-include-long-make-via-1-line-opt-O1
language-c---example-1-cwrap-include-long-make-via-1-line-opt-O2
language-c---example-1-cwrap-include-long-make-via-1-line-opt-O3
language-c---example-1-cwrap-include-long-make-via-n-line-opt-O0
language-c---example-1-cwrap-include-long-make-via-n-line-opt-O1
language-c---example-1-cwrap-include-long-make-via-n-line-opt-O2
language-c---example-1-cwrap-include-long-make-via-n-line-opt-O3
language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O0
language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O1
language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O2
language-cpp-example-1-cwrap-exclude------make-via-1-line-opt-O3
language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O0
language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O1
language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O2
language-cpp-example-1-cwrap-exclude------make-via-n-line-opt-O3
language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O0
language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O1
language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O2
language-cpp-example-1-cwrap-include-curt-make-via-1-line-opt-O3
language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O0
language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O1
language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O2
language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O3
language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O0
language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O1
language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O2
language-cpp-example-1-cwrap-include-long-make-via-1-line-opt-O3
language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O0
language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O1
language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O2
language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3
makefile
```

- The uber makefile  is an easy way to build all the tests in parallel.
- A particular build folder looks like this after the tests ran:
```
$ ls -1 build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/
build.log
c---example-1.a.c
c---example-1.b.c
c---example-1.exclude-----.output.txt
c---example-1.include-curt.output.txt
c---example-1.include-long.output.txt
c---example-1.via-1-line.mak
c---example-1.via-n-line.mak
cpp-example-1.a.cpp
cpp-example-1.a.hpp
cpp-example-1.a.o
cpp-example-1.a.o.cwrap.log
cpp-example-1.a.s
cpp-example-1.a.s.2.s
cpp-example-1.b.cpp
cpp-example-1.b.hpp
cpp-example-1.b.o
cpp-example-1.b.o.cwrap.log
cpp-example-1.b.s
cpp-example-1.b.s.2.s
cpp-example-1.exclude-----.output.txt
cpp-example-1.include-curt.output.txt
cpp-example-1.include-long.output.txt
cpp-example-1.via-1-line.mak
cpp-example-1.via-n-line.cwrap.c
cpp-example-1.via-n-line.exe
cpp-example-1.via-n-line.exe.cwrap.log
cpp-example-1.via-n-line.mak
cwrap.h
run.log
```
- The `.s` files are the gcc generated assembler files, via the cwrap modified gcc command line.
- The `.s.2.s` files are the cwrap modifed assembler files.
- Here is an example of the modified assembler for the generic enter function call for `clean_up()` function.
- The original assembler just calls `__cyg_profile_func_enter()`.
- The modified assembler only calls the enter function if the function verbosity matches the global verbosity level.
- In addition the auto generated struct instance `cwrap_data__Z8clean_upPi` is passed to the enter function.
```
$ diff build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.b.s build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.b.s.2.s
46c46,57
<       call    __cyg_profile_func_enter@PLT
---
>
>
>     movq    cwrap_log_verbosity@GOTPCREL(%rip), %rax
>     movl    (%rax), %edx
>     movq    cwrap_data__Z8clean_upPi@GOTPCREL(%rip), %rsi
>     movl    (%rsi), %eax
>     cmpl    %eax, %edx
>     jl  .L_cwrap_skip_cyg_profile_func_45
>       call    __cyg_profile_func_enter@PLT # <-- rdi=&_Z8clean_upPi, rsi=&cwrap_data__Z8clean_upPi
> .L_cwrap_skip_cyg_profile_func_45:
...
```
- As an example, the auto generated struct instance `cwrap_data__Z8clean_upPi` can be found here:
```
$ cat build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.via-n-line.cwrap.c | egrep "CWRAP_DATA cwrap_data__Z8clean_upPi"
CWRAP_DATA cwrap_data__Z8clean_upPi = {9, CWRAP_MAGIC, 0, 1, 1, 13, 14, "clean_up", 8, "cpp-example-1.b.o", 17, NULL, &cwrap_data__Z7get_maxIiET_S0_S0_};
```

- The `.o.cwrap.log` files detail what happened at each compile step, e.g.:
```
$ cat build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.b.o.cwrap.log
0.041538 - cwrap: os_release  : PRETTY_NAME="Ubuntu 19.10"
0.041542 - cwrap: arguments   : g++ -DCWRAP_LOG_CURT=0 -O3 -Werror -g -o cpp-example-1.b.o -c cpp-example-1.b.cpp
0.041552 - cwrap: cwd         : ./cwrap/test/build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3
0.041556 - cwrap: gcc_out_file: cpp-example-1.b.o
0.041561 - cwrap: gcc_out_path:
0.041563 - cwrap: gcc_out_name: cpp-example-1.b
0.041572 - cwrap: gcc_out_ext : .o
0.041624 - cwrap: source file arguments: 1 (cpp-example-1.b.cpp)
0.041636 - cwrap: exe    file arguments: 0 ()
0.041670 - cwrap: checking if new contents different to old contents for header file: cwrap.h
0.078291 - cwrap: c/cpp to assembler: running: g++ -DCWRAP_LOG_CURT=0 -O3 -Werror -g -S -fPIC -c cpp-example-1.b.cpp -finstrument-functions -I. --include cwrap.h
> <no output>
> <exit(0)> in 0.285778 seconds building assembler for cpp-example-1.b.o
0.364180 - cwrap: munging assembler files
0.386323 - cwrap: assembler file: name : < /home/simon/20200413-cwrap/cwrap/test/build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.b.s <-- 3074 lines
0.386578 - cwrap: assembler file: found '.type <function name>, @function' instances: 7 in 0.000243s
0.386858 - cwrap: assembler file: found '.cfi_endproc' instances: 7 in 0.000273s
0.386862 - cwrap: assembler file: finding function name associated with each enter|exit
0.386878   - cwrap: assembler file: line 17 to 117 for function _Z8clean_upPi() expanded to .cold function; line 17 to 139
0.386912   - cwrap: assembler file: line 17 to 139 for function with 3 enter|exits: _Z8clean_upPi()
0.386918     - cwrap: match_enter_exit_with_mangled_names: searching in 123 lines 17 to 139 of 3074 lines in file
0.387003     - cwrap: match_enter_exit_with_mangled_names: squashed down to 20 lines
0.387052     - cwrap: match_enter_exit_with_mangled_names: found .L000:
0.387080     - cwrap: match_enter_exit_with_mangled_names: found        movq rbp <-- &_Z8clean_upPi
0.387092     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387101     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_enter(_Z8clean_upPi) #1
0.387110     - cwrap: match_enter_exit_with_mangled_names: found        jl .L3
0.387126     - cwrap: match_enter_exit_with_mangled_names: found        je .L8
0.387133     - cwrap: match_enter_exit_with_mangled_names: found .L3:
0.387139     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387146     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(_Z8clean_upPi) #2 indirect via jump via .L3 and register rbp
0.387149     - cwrap: match_enter_exit_with_mangled_names: found .L8:
0.387151     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L3
0.387155     - cwrap: match_enter_exit_with_mangled_names: found .L5:
0.387157     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L4
0.387160     - cwrap: match_enter_exit_with_mangled_names: found .L4:
0.387162     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387168     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(?) #3
0.387171     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- r12
0.387172     - cwrap: match_enter_exit_with_mangled_names: found enter exit functions: 3
0.387175     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #1 _Z8clean_upPi()
0.387181     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #2 _Z8clean_upPi()
0.387188     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #3 _Z8clean_upPi() <-- assigned because unique register rbp value
0.387261     - cwrap: assembler file: line 45: call __cyg_profile_func_enter@PLT # <-- rdi=&_Z8clean_upPi, rsi=&cwrap_data__Z8clean_upPi
0.387278     - cwrap: assembler file: line 79: jmp __cyg_profile_func_exit@PLT # <-- rdi=&_Z8clean_upPi, rsi=&cwrap_data__Z8clean_upPi
0.387288     - cwrap: assembler file: line 132: call __cyg_profile_func_exit@PLT # <-- rdi=&_Z8clean_upPi, rsi=&cwrap_data__Z8clean_upPi
0.387320   - cwrap: assembler file: line 172 to 254 for function with 2 enter|exits: _ZN9my_structD2Ev()
0.387344     - cwrap: assembler file: line 198: call __cyg_profile_func_enter@PLT # <-- rdi=&_ZN9my_structD2Ev, rsi=&cwrap_data__ZN9my_structD2Ev
0.387355     - cwrap: assembler file: line 236: jmp __cyg_profile_func_exit@PLT # <-- rdi=&_ZN9my_structD2Ev, rsi=&cwrap_data__ZN9my_structD2Ev
0.387387   - cwrap: assembler file: line 285 to 420 for function with 3 enter|exits: _ZN9my_structC2EPKc()
0.387391     - cwrap: match_enter_exit_with_mangled_names: searching in 136 lines 285 to 420 of 3074 lines in file
0.387473     - cwrap: match_enter_exit_with_mangled_names: squashed down to 26 lines
0.387478     - cwrap: match_enter_exit_with_mangled_names: found .L000:
0.387490     - cwrap: match_enter_exit_with_mangled_names: found        movq r12 <-- &_ZN9my_structC2EPKc
0.387495     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- r12
0.387502     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_enter(_ZN9my_structC2EPKc) #1
0.387508     - cwrap: match_enter_exit_with_mangled_names: found        jl .L14
0.387514     - cwrap: match_enter_exit_with_mangled_names: found        je .L19
0.387520     - cwrap: match_enter_exit_with_mangled_names: found .L14:
0.387524     - cwrap: match_enter_exit_with_mangled_names: found        jg .L15
0.387528     - cwrap: match_enter_exit_with_mangled_names: found        je .L20
0.387531     - cwrap: match_enter_exit_with_mangled_names: found .L15:
0.387533     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- r12
0.387540     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(?) #2
0.387542     - cwrap: match_enter_exit_with_mangled_names: found .L19:
0.387545     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L14
0.387548     - cwrap: match_enter_exit_with_mangled_names: found .L20:
0.387550     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L15
0.387552     - cwrap: match_enter_exit_with_mangled_names: found .L17:
0.387555     - cwrap: match_enter_exit_with_mangled_names: found .L16:
0.387557     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- r12
0.387571     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(?) #3
0.387574     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387576     - cwrap: match_enter_exit_with_mangled_names: found enter exit functions: 3
0.387578     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #1 _ZN9my_structC2EPKc()
0.387591     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #2 _ZN9my_structC2EPKc() <-- assigned because unique register r12 value
0.387596     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #3 _ZN9my_structC2EPKc() <-- assigned because unique register r12 value
0.387624     - cwrap: assembler file: line 314: call __cyg_profile_func_enter@PLT # <-- rdi=&_ZN9my_structC2EPKc, rsi=&cwrap_data__ZN9my_structC2EPKc
0.387636     - cwrap: assembler file: line 375: jmp __cyg_profile_func_exit@PLT # <-- rdi=&_ZN9my_structC2EPKc, rsi=&cwrap_data__ZN9my_structC2EPKc
0.387645     - cwrap: assembler file: line 413: call __cyg_profile_func_exit@PLT # <-- rdi=&_ZN9my_structC2EPKc, rsi=&cwrap_data__ZN9my_structC2EPKc
0.387657   - cwrap: assembler file: line 454 to 640 for function _Z41__static_initialization_and_destruction_0ii() expanded to .cold function; line 454 to 676
0.387691   - cwrap: assembler file: line 454 to 676 for function with 6 enter|exits: _Z41__static_initialization_and_destruction_0ii()
0.387695     - cwrap: match_enter_exit_with_mangled_names: searching in 223 lines 454 to 676 of 3074 lines in file
0.387816     - cwrap: match_enter_exit_with_mangled_names: squashed down to 44 lines
0.387821     - cwrap: match_enter_exit_with_mangled_names: found .L000:
0.387832     - cwrap: match_enter_exit_with_mangled_names: found        leaq rdi <-- &_Z41__static_initialization_and_destruction_0ii
0.387840     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_enter(_Z41__static_initialization_and_destruction_0ii) #1
0.387844     - cwrap: match_enter_exit_with_mangled_names: found        jne .L22
0.387850     - cwrap: match_enter_exit_with_mangled_names: found        je .L38
0.387854     - cwrap: match_enter_exit_with_mangled_names: found .L22:
0.387860     - cwrap: match_enter_exit_with_mangled_names: found        leaq rdi <-- &_Z41__static_initialization_and_destruction_0ii
0.387865     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(_Z41__static_initialization_and_destruction_0ii) #2
0.387867     - cwrap: match_enter_exit_with_mangled_names: found .L38:
0.387873     - cwrap: match_enter_exit_with_mangled_names: found        movq rbp <-- &_ZN9my_structC2EPKc
0.387876     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387880     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_enter(_ZN9my_structC2EPKc) #3
0.387886     - cwrap: match_enter_exit_with_mangled_names: found        movq r12 <-- &my_struct_2
0.387890     - cwrap: match_enter_exit_with_mangled_names: found        jl .L23
0.387896     - cwrap: match_enter_exit_with_mangled_names: found        je .L39
0.387902     - cwrap: match_enter_exit_with_mangled_names: found .L23:
0.387905     - cwrap: match_enter_exit_with_mangled_names: found        jg .L24
0.387909     - cwrap: match_enter_exit_with_mangled_names: found        je .L40
0.387911     - cwrap: match_enter_exit_with_mangled_names: found .L24:
0.387913     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387919     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(?) #4
0.387925     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- &_ZN9my_structD1Ev
0.387933     - cwrap: match_enter_exit_with_mangled_names: found        leaq rdx <-- &__dso_handle
0.387937     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L22
0.387941     - cwrap: match_enter_exit_with_mangled_names: found .L39:
0.387944     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L23
0.387950     - cwrap: match_enter_exit_with_mangled_names: found .L40:
0.387953     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L24
0.387956     - cwrap: match_enter_exit_with_mangled_names: found .L28:
0.387959     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L27
0.387962     - cwrap: match_enter_exit_with_mangled_names: found .L29:
0.387964     - cwrap: match_enter_exit_with_mangled_names: found        jmp .L26
0.387967     - cwrap: match_enter_exit_with_mangled_names: found .L26:
0.387969     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387975     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(?) #5
0.387978     - cwrap: match_enter_exit_with_mangled_names: found .L27:
0.387982     - cwrap: match_enter_exit_with_mangled_names: found        leaq rdi <-- &_Z41__static_initialization_and_destruction_0ii
0.387988     - cwrap: match_enter_exit_with_mangled_names: found        __cyg_profile_func_exit(_Z41__static_initialization_and_destruction_0ii) #6
0.387991     - cwrap: match_enter_exit_with_mangled_names: found        movq rdi <-- rbp
0.387992     - cwrap: match_enter_exit_with_mangled_names: found enter exit functions: 6
0.387994     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #1 _Z41__static_initialization_and_destruction_0ii()
0.387996     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #2 _Z41__static_initialization_and_destruction_0ii()
0.387997     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #3 _ZN9my_structC2EPKc()
0.388002     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #4 _ZN9my_structC2EPKc() <-- assigned because unique register rbp value
0.388007     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #5 _ZN9my_structC2EPKc() <-- assigned because unique register rbp value
0.388008     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #6 _Z41__static_initialization_and_destruction_0ii()
0.388094     - cwrap: assembler file: line 483: call __cyg_profile_func_enter@PLT # <-- rdi=&_Z41__static_initialization_and_destruction_0ii, rsi=&cwrap_data__Z41__static_initialization_and_destruction_0ii
0.388112     - cwrap: assembler file: line 502: jmp __cyg_profile_func_exit@PLT # <-- rdi=&_Z41__static_initialization_and_destruction_0ii, rsi=&cwrap_data__Z41__static_initialization_and_destruction_0ii
0.388122     - cwrap: assembler file: line 519: call __cyg_profile_func_enter@PLT # <-- rdi=&_ZN9my_structC2EPKc, rsi=&cwrap_data__ZN9my_structC2EPKc
0.388144     - cwrap: assembler file: line 570: call __cyg_profile_func_exit@PLT # <-- rdi=&_ZN9my_structC2EPKc, rsi=&cwrap_data__ZN9my_structC2EPKc
0.388152     - cwrap: assembler file: line 662: call __cyg_profile_func_exit@PLT # <-- rdi=&_ZN9my_structC2EPKc, rsi=&cwrap_data__ZN9my_structC2EPKc
0.388162     - cwrap: assembler file: line 669: call __cyg_profile_func_exit@PLT # <-- rdi=&_Z41__static_initialization_and_destruction_0ii, rsi=&cwrap_data__Z41__static_initialization_and_destruction_0ii
0.388185   - cwrap: assembler file: line 700 to 723 for function with 2 enter|exits: _GLOBAL__sub_I_cpp_example_1.b.cpp()
0.388200     - cwrap: assembler file: line 710: call __cyg_profile_func_enter@PLT # <-- rdi=&_GLOBAL__sub_I_cpp_example_1.b.cpp, rsi=&cwrap_data__GLOBAL__sub_I_cpp_example_1.b.cpp (converted dots to underscores)
0.388211     - cwrap: assembler file: line 721: jmp __cyg_profile_func_exit@PLT # <-- rdi=&_GLOBAL__sub_I_cpp_example_1.b.cpp, rsi=&cwrap_data__GLOBAL__sub_I_cpp_example_1.b.cpp (converted dots to underscores)
0.388401 - cwrap: found pushsection __cwrap instances: 6 in 0.000178s
0.388672   - cwrap: starting at line 50: .pushsection __cwrap, "S", @note; .int 7; .asciz "$.LC0"; .popsection; line=7 label=.LC0 pretty_function=void clean_up(int*) AKA _Z8clean_upPi mangled
0.388763   - cwrap: starting at line 205: .pushsection __cwrap, "S", @note; .int 4; .asciz "$.LC3"; .popsection; line=4 label=.LC3 pretty_function=my_struct::~my_struct() AKA _ZN9my_structD2Ev mangled
0.388808   - cwrap: starting at line 324: .pushsection __cwrap, "S", @note; .int 0; .asciz "$.LC5"; .popsection; line=0 label=.LC5 pretty_function=my_struct::my_struct(const char*) AKA _ZN9my_structC2EPKc mangled
0.388842   - cwrap: starting at line 346: .pushsection __cwrap, "S", @note; .int 1; .asciz "$.LC5"; .popsection; line=1 label=.LC5 pretty_function=my_struct::my_struct(const char*) AKA _ZN9my_structC2EPKc mangled
0.388869   - cwrap: starting at line 531: .pushsection __cwrap, "S", @note; .int 0; .asciz "$.LC5"; .popsection; line=0 label=.LC5 pretty_function=my_struct::my_struct(const char*) AKA _ZN9my_structC2EPKc mangled
0.388896   - cwrap: starting at line 552: .pushsection __cwrap, "S", @note; .int 1; .asciz "$.LC5"; .popsection; line=1 label=.LC5 pretty_function=my_struct::my_struct(const char*) AKA _ZN9my_structC2EPKc mangled
0.388916 - cwrap: rewriting 1 dodgy dot labels
0.388925   - cwrap: rewriting dodgy dot label _GLOBAL__sub_I_cpp_example_1.b.cpp to _GLOBAL__sub_I_cpp_example_1_b_cpp
0.389114 - cwrap: assembler file: name : > /home/simon/20200413-cwrap/cwrap/test/build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.b.s.2.s
0.389618 - cwrap: no undefined cwrap_data_*: running: g++ -DCWRAP_LOG_CURT=0 -O3 -Werror -g -o cpp-example-1.b.o -c /home/simon/20200413-cwrap/cwrap/test/build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.b.s.2.s
> <no output>
> <exit(0)> in 0.098059 seconds building object or shared object for cpp-example-1.b.o
0.488426 - cwrap: done in 0.488426 seconds
```

- The `.cwrap.c` file is the newly created, extra cwrap C code and struct instances to be compiled and linked.
- Each auto instrumented function gets its own struct instance prefixed with `cwrap_data_`.
- In this particular build there are 24 functions auto instrumented (the 25th is a dummy).
```
$ cat build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.via-n-line.cwrap.c | egrep "^CWRAP_DATA" | wc -l
25
$ cat build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.via-n-line.cwrap.c | egrep "^CWRAP_DATA"
CWRAP_DATA cwrap_data__GLOBAL__sub_I_cpp_example_1_a_cpp = {9, CWRAP_MAGIC, 0, 1, 1, 34, 34, "_GLOBAL__sub_I_cpp_example_1_a_cpp", 34, "cpp-example-1.a.o", 17, NULL, NULL};
CWRAP_DATA cwrap_data__GLOBAL__sub_I_cpp_example_1_b_cpp = {9, CWRAP_MAGIC, 0, 1, 1, 34, 34, "_GLOBAL__sub_I_cpp_example_1_b_cpp", 34, "cpp-example-1.b.o", 17, NULL, &cwrap_data__GLOBAL__sub_I_cpp_example_1_a_cpp};
CWRAP_DATA cwrap_data__Z3bazi = {9, CWRAP_MAGIC, 0, 1, 1, 7, 8, "baz", 3, "cpp-example-1.a.o", 17, NULL, &cwrap_data__GLOBAL__sub_I_cpp_example_1_b_cpp};
CWRAP_DATA cwrap_data__Z3byev = {9, CWRAP_MAGIC, 0, 1, 1, 7, 5, "bye", 3, "cpp-example-1.a.o", 17, NULL, &cwrap_data__Z3bazi};
CWRAP_DATA cwrap_data__Z41__static_initialization_and_destruction_0ii = {9, CWRAP_MAGIC, 0, 1, 1, 47, 51, "__static_initialization_and_destruction_0", 41, "cpp-example-1.a.o", 17, NULL, &cwrap_data__Z3byev};
CWRAP_DATA cwrap_data__Z7bye_bazv = {9, CWRAP_MAGIC, 0, 1, 1, 11, 9, "bye_baz", 7, "cpp-example-1.a.o", 17, NULL, &cwrap_data__Z41__static_initialization_and_destruction_0ii};
CWRAP_DATA cwrap_data__Z7get_maxIcET_S0_S0_ = {9, CWRAP_MAGIC, 0, 1, 1, 21, 30, "char get_max<>", 14, "cpp-example-1.a.o", 17, NULL, &cwrap_data__Z7bye_bazv};
CWRAP_DATA cwrap_data__Z7get_maxIiET_S0_S0_ = {9, CWRAP_MAGIC, 0, 1, 1, 21, 26, "int get_max<>", 13, "cpp-example-1.a.o", 17, NULL, &cwrap_data__Z7get_maxIcET_S0_S0_};
CWRAP_DATA cwrap_data__Z8clean_upPi = {9, CWRAP_MAGIC, 0, 1, 1, 13, 14, "clean_up", 8, "cpp-example-1.b.o", 17, NULL, &cwrap_data__Z7get_maxIiET_S0_S0_};
CWRAP_DATA cwrap_data__ZL3bari = {9, CWRAP_MAGIC, 0, 1, 1, 8, 8, "bar", 3, "cpp-example-1.a.o", 17, NULL, &cwrap_data__Z8clean_upPi};
CWRAP_DATA cwrap_data__ZL3quxv = {9, CWRAP_MAGIC, 0, 1, 1, 8, 5, "qux", 3, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZL3bari};
CWRAP_DATA cwrap_data__ZL4quuxi = {9, CWRAP_MAGIC, 0, 1, 1, 9, 9, "quux", 4, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZL3quxv};
CWRAP_DATA cwrap_data__ZN3Foo10my_privateEi = {9, CWRAP_MAGIC, 0, 1, 1, 21, 20, "Foo::my_private", 15, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZL4quuxi};
CWRAP_DATA cwrap_data__ZN3Foo9my_publicEi = {9, CWRAP_MAGIC, 0, 1, 1, 19, 19, "Foo::my_public", 14, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZN3Foo10my_privateEi};
CWRAP_DATA cwrap_data__ZN3FooC2EPKc = {9, CWRAP_MAGIC, 0, 1, 1, 13, 21, "Foo::Foo", 8, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZN3Foo9my_publicEi};
CWRAP_DATA cwrap_data__ZN3FooD2Ev = {9, CWRAP_MAGIC, 0, 1, 1, 11, 11, "Foo::~Foo", 9, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZN3FooC2EPKc};
CWRAP_DATA cwrap_data__ZN9my_structC2EPKc = {9, CWRAP_MAGIC, 0, 1, 2, 19, 33, "my_struct::my_struct", 20, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZN3FooD2Ev};
CWRAP_DATA cwrap_data__ZN9my_structC2EPKcS1_ = {9, CWRAP_MAGIC, 0, 2, 2, 22, 46, "my_struct::my_struct", 20, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZN9my_structC2EPKc};
CWRAP_DATA cwrap_data__ZN9my_structD2Ev = {9, CWRAP_MAGIC, 0, 1, 1, 17, 23, "my_struct::~my_struct", 21, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZN9my_structC2EPKcS1_};
CWRAP_DATA cwrap_data_main = {9, CWRAP_MAGIC, 0, 1, 1, 4, 4, "main", 4, "cpp-example-1.a.o", 17, NULL, &cwrap_data__ZN9my_structD2Ev};
CWRAP_DATA cwrap_data_cwrap_log_quiet_until = {9, CWRAP_MAGIC, 0, 1, 1, 21, 21, "cwrap_log_quiet_until", 21, "cpp-example-1.via-n-line.cwrap.c", 32, NULL, &cwrap_data_main};
CWRAP_DATA cwrap_data_cwrap_log_verbosity_set = {9, CWRAP_MAGIC, 0, 1, 1, 23, 23, "cwrap_log_verbosity_set", 23, "cpp-example-1.via-n-line.cwrap.c", 32, NULL, &cwrap_data_cwrap_log_quiet_until};
CWRAP_DATA cwrap_data_cwrap_log_stats = {9, CWRAP_MAGIC, 0, 1, 1, 15, 15, "cwrap_log_stats", 15, "cpp-example-1.via-n-line.cwrap.c", 32, NULL, &cwrap_data_cwrap_log_verbosity_set};
CWRAP_DATA cwrap_data_cwrap_log_show = {9, CWRAP_MAGIC, 0, 1, 1, 14, 14, "cwrap_log_show", 14, "cpp-example-1.via-n-line.cwrap.c", 32, NULL, &cwrap_data_cwrap_log_stats};
CWRAP_DATA * cwrap_data_start = &cwrap_data_cwrap_log_show;
```

- The `.exe.cwrap.log` file details what happened at the link step:
```
$ cat build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.via-n-line.exe.cwrap.log
0.022434 - cwrap: os_release  : PRETTY_NAME="Ubuntu 19.10"
0.022439 - cwrap: arguments   : gcc -DCWRAP_LOG_CURT=0 -Werror -g -o cpp-example-1.via-n-line.exe cpp-example-1.a.o cpp-example-1.b.o -lstdc++
0.022445 - cwrap: cwd         : ./cwrap/test/build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3
0.022449 - cwrap: gcc_out_file: cpp-example-1.via-n-line.exe
0.022453 - cwrap: gcc_out_path:
0.022455 - cwrap: gcc_out_name: cpp-example-1.via-n-line
0.022464 - cwrap: gcc_out_ext : .exe
0.022524 - cwrap: source file arguments: 0 ()
0.022535 - cwrap: exe    file arguments: 1 (cpp-example-1.via-n-line.exe)
0.022540 - cwrap: gcc arguments create executable
0.022564 - cwrap: constructing two nm commands from gcc command
0.022588 - cwrap: discarding gcc command  line option: gcc
0.022593 - cwrap: discarding gcc command  line option: -DCWRAP_LOG_CURT=0
0.022599 - cwrap: discarding gcc command  line option: -Werror
0.022600 - cwrap: discarding gcc command  line option: -g
0.022601 - cwrap: discarding gcc command  line option: -o
0.022604 - cwrap: discarding gcc command  line option: cpp-example-1.via-n-line.exe
0.022611 - cwrap: discarding gcc command  line option: -lstdc++
0.022613 - cwrap: object to binary #1: running via nm #1 (because no source files detected and nm faster than gxx): nm --print-file-name --no-sort --undefined-only cpp-example-1.a.o cpp-example-1.b.o 2>&1 | egrep cwrap_data_
0.094790 - cwrap: discarding gcc command  line option: gcc
0.094810 - cwrap: discarding gcc command  line option: -DCWRAP_LOG_CURT=0
0.094817 - cwrap: discarding gcc command  line option: -Werror
0.094819 - cwrap: discarding gcc command  line option: -g
0.094820 - cwrap: discarding gcc command  line option: -o
0.094825 - cwrap: discarding gcc command  line option: cpp-example-1.via-n-line.exe
0.094832 - cwrap: discarding gcc command  line option: -lstdc++
0.094834 - cwrap: object to binary #1: running via nm #2 (because no source files detected and nm faster than gxx): nm --print-file-name --no-sort --undefined-only --dynamic cpp-example-1.a.o cpp-example-1.b.o 2>&1 | egrep cwrap_data_
0.124199 - cwrap: using undefines from nm; auto generating: cpp-example-1.via-n-line.cwrap.c
0.124249 - cwrap: examining lines of nm output: 23
0.124358 - cwrap: unique undefined cwrap_data_* symbols in nm output: 20
0.124546 - cwrap: writing 20 missing cwrap structs to: cpp-example-1.via-n-line.cwrap.c
0.125055   - cwrap: number___mangled_names=24
0.125061   - cwrap: number_demangled_names=24
0.125062   - cwrap: number___generic_names=23
0.125064   - cwrap:  bytes___mangled_names=419
0.125065   - cwrap:  bytes_demangled_names=483
0.125066   - cwrap:  bytes___generic_names=331
0.125074   - cwrap: _GLOBAL__sub_I_cpp_example_1_a_cpp               -> variation 1 of 1 for _GLOBAL__sub_I_cpp_example_1_a_cpp()
0.125087   - cwrap: _GLOBAL__sub_I_cpp_example_1_b_cpp               -> variation 1 of 1 for _GLOBAL__sub_I_cpp_example_1_b_cpp()
0.125104   - cwrap: _Z3bazi                                          -> variation 1 of 1 for baz()
0.125120   - cwrap: _Z3byev                                          -> variation 1 of 1 for bye()
0.125134   - cwrap: _Z41__static_initialization_and_destruction_0ii  -> variation 1 of 1 for __static_initialization_and_destruction_0()
0.125146   - cwrap: _Z7bye_bazv                                      -> variation 1 of 1 for bye_baz()
0.125182   - cwrap: _Z7get_maxIcET_S0_S0_                            -> variation 1 of 1 for char get_max<>()
0.125198   - cwrap: _Z7get_maxIiET_S0_S0_                            -> variation 1 of 1 for int get_max<>()
0.125211   - cwrap: _Z8clean_upPi                                    -> variation 1 of 1 for clean_up()
0.125223   - cwrap: _ZL3bari                                         -> variation 1 of 1 for bar()
0.125234   - cwrap: _ZL3quxv                                         -> variation 1 of 1 for qux()
0.125246   - cwrap: _ZL4quuxi                                        -> variation 1 of 1 for quux()
0.125259   - cwrap: _ZN3Foo10my_privateEi                            -> variation 1 of 1 for Foo::my_private()
0.125274   - cwrap: _ZN3Foo9my_publicEi                              -> variation 1 of 1 for Foo::my_public()
0.125287   - cwrap: _ZN3FooC2EPKc                                    -> variation 1 of 1 for Foo::Foo()
0.125299   - cwrap: _ZN3FooD2Ev                                      -> variation 1 of 1 for Foo::~Foo()
0.125313   - cwrap: _ZN9my_structC2EPKc                              -> variation 1 of 2 for my_struct::my_struct()
0.125331   - cwrap: _ZN9my_structC2EPKcS1_                           -> variation 2 of 2 for my_struct::my_struct()
0.125346   - cwrap: _ZN9my_structD2Ev                                -> variation 1 of 1 for my_struct::~my_struct()
0.125354   - cwrap: main                                             -> variation 1 of 1 for main()
0.125363   - cwrap: cwrap_log_quiet_until                            -> variation 1 of 1 for cwrap_log_quiet_until()
0.125371   - cwrap: cwrap_log_verbosity_set                          -> variation 1 of 1 for cwrap_log_verbosity_set()
0.125378   - cwrap: cwrap_log_stats                                  -> variation 1 of 1 for cwrap_log_stats()
0.125386   - cwrap: cwrap_log_show                                   -> variation 1 of 1 for cwrap_log_show()
0.125522 - cwrap: object to binary #2: running: gcc -DCWRAP_LOG_CURT=0 -Werror -g -o cpp-example-1.via-n-line.exe cpp-example-1.a.o cpp-example-1.b.o -lstdc++ -fPIC cpp-example-1.via-n-line.cwrap.c -Wl,--undefined,cwrap_log_init -lunwind -fuse-ld=gold
> <no output>
> <exit(0)> in 0.210366 seconds building binary for cpp-example-1.via-n-line.exe
0.336436 - cwrap: done in 0.336436 seconds
```

- The `.exe` file is the final executable after linking.
- Running the executable with `CWRAP_LOG_SHOW=1` tells it to list its instrumented functions:
```
$ CWRAP_LOG_SHOW=1 ./build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/cpp-example-1.via-n-line.exe
C0 + cwrap_log_show() { #1
C0   - func_addr=(nil)
C0   - #1: verbosity 9 for 1 of 1 function variation for cwrap_log_show() from cpp-example-1.via-n-line.cwrap.c
C0   - #2: verbosity 9 for 1 of 1 function variation for cwrap_log_stats() from cpp-example-1.via-n-line.cwrap.c
C0   - #3: verbosity 9 for 1 of 1 function variation for cwrap_log_verbosity_set() from cpp-example-1.via-n-line.cwrap.c
C0   - #4: verbosity 9 for 1 of 1 function variation for cwrap_log_quiet_until() from cpp-example-1.via-n-line.cwrap.c
C0   - #5: verbosity 9 for 1 of 1 function variation for main() from cpp-example-1.a.o
C0   - #6: verbosity 9 for 1 of 1 function variation for my_struct::~my_struct() from cpp-example-1.a.o
C0   - #7: verbosity 9 for 2 of 2 function variation for my_struct::my_struct() from cpp-example-1.a.o
C0   - #8: verbosity 9 for 1 of 2 function variation for my_struct::my_struct() from cpp-example-1.a.o
C0   - #9: verbosity 9 for 1 of 1 function variation for Foo::~Foo() from cpp-example-1.a.o
C0   - #10: verbosity 9 for 1 of 1 function variation for Foo::Foo() from cpp-example-1.a.o
C0   - #11: verbosity 9 for 1 of 1 function variation for Foo::my_public() from cpp-example-1.a.o
C0   - #12: verbosity 9 for 1 of 1 function variation for Foo::my_private() from cpp-example-1.a.o
C0   - #13: verbosity 9 for 1 of 1 function variation for quux() from cpp-example-1.a.o
C0   - #14: verbosity 9 for 1 of 1 function variation for qux() from cpp-example-1.a.o
C0   - #15: verbosity 9 for 1 of 1 function variation for bar() from cpp-example-1.a.o
C0   - #16: verbosity 9 for 1 of 1 function variation for clean_up() from cpp-example-1.b.o
C0   - #17: verbosity 9 for 1 of 1 function variation for int get_max<>() from cpp-example-1.a.o
C0   - #18: verbosity 9 for 1 of 1 function variation for char get_max<>() from cpp-example-1.a.o
C0   - #19: verbosity 9 for 1 of 1 function variation for bye_baz() from cpp-example-1.a.o
C0   - #20: verbosity 9 for 1 of 1 function variation for __static_initialization_and_destruction_0() from cpp-example-1.a.o
C0   - #21: verbosity 9 for 1 of 1 function variation for bye() from cpp-example-1.a.o
C0   - #22: verbosity 9 for 1 of 1 function variation for baz() from cpp-example-1.a.o
C0   - #23: verbosity 9 for 1 of 1 function variation for _GLOBAL__sub_I_cpp_example_1_b_cpp() from cpp-example-1.b.o
C0   - #24: verbosity 9 for 1 of 1 function variation for _GLOBAL__sub_I_cpp_example_1_a_cpp() from cpp-example-1.a.o
C0   } // cwrap_log_show()
```

- The `run.log` file contains the output of the final executable run multiple time with different cwrap options.
- Note: In this case, the output is the 'long' cwrap output and not the 'curt' cwrap output.
- Note: The cwrap environment variable options are initially shown by `cwrap_log_init()` upon process start.
- Note: The output shows all the C++ activity that happens before `main()` is called.
- Note: `cwrap_log_verbosity_set()` is called within the example C++ source code to dynamically change the verbosity at run-time.
```
$ cat build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/run.log
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}~<keyword>][:...]) _STATS=1 _SHOW=0 _CURT=0 _FILE=0 _NUM=0 _COR_ID=1 _THREAD_ID=0 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
C0 + cwrap_log_verbosity_set() { #1
C0   - verbosity=1
C0   - [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 1 set for 24 matches in 24 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
C0   } // cwrap_log_verbosity_set()
C0 + _GLOBAL__sub_I_cpp_example_1_a_cpp() { #1
C0   + __static_initialization_and_destruction_0() { #1
C0     + my_struct::my_struct() { #1
C0       - arg1=my_struct_1
C0       - constructing my_struct
C0       } // my_struct::my_struct()
C0     } // __static_initialization_and_destruction_0()
C0   } // _GLOBAL__sub_I_cpp_example_1_a_cpp()
C0 + _GLOBAL__sub_I_cpp_example_1_b_cpp() { #1
C0   + __static_initialization_and_destruction_0() { #2
C0     + my_struct::my_struct() { #2
C0       - arg1=my_struct_2
C0       - constructing my_struct
C0       } // my_struct::my_struct()
C0     } // __static_initialization_and_destruction_0()
C0   } // _GLOBAL__sub_I_cpp_example_1_b_cpp()
C0 + main() { #1
C0   + qux() { #1
C0     + quux() { #1
C0       - return r=2
C0       } // quux()
C0     + quux() { #2
C0       - return r=3
C0       } // quux()
C0     + quux() { #3
C0       - return r=4
C0       } // quux()
C0     } // qux()
C0   + bar() { #1
C0     - a=0
C0     + baz() { #1
C0       - a=1
C0       - return r=2
C0       } // baz()
C0     - return r=2
C0     } // bar()
C0   + cwrap_log_verbosity_set() { #2
C0     - verbosity=2=function~bar
C0     - [cwrap_log_verbosity_set() ignores verbosity!]
C0     - verbosity 2 set for 1 matches in 24 functions for 14 byte clause '2=function~bar' // type=FUNCTION keyword=bar
C0     } // cwrap_log_verbosity_set()
C0   + baz() { #2
C0     - a=2
C0     - return r=3
C0     } // baz()
C0   + baz() { #3
C0     - a=3
C0     - return r=4
C0     } // baz()
C0   - hello world
C0   + baz() { #4
C0     - a=1
C0     - return r=2
C0     } // baz()
C0   + int get_max<>() { #1
C0     - a=12345, b=67890
C0     - return r=67890
C0     } // int get_max<>()
C0   + char get_max<>() { #1
C0     - a=43, b=21
C0     - return r=43
C0     } // char get_max<>()
C0   + my_struct::my_struct() { #3
C0     - arg1=my_struct_2
C0     - constructing my_struct
C0     } // my_struct::my_struct()
C0   + Foo::Foo() { #1
C0     + my_struct::my_struct() { #1
C0       - arg1=my_struct_3, arg2=a
C0       - constructing my_struct
C0       } // my_struct::my_struct()
C0     - constructing Foo
C0     - inside Foo
C0     } // Foo::Foo()
C0   + Foo::Foo() { #2
C0     + my_struct::my_struct() { #2
C0       - arg1=my_struct_3, arg2=b
C0       - constructing my_struct
C0       } // my_struct::my_struct()
C0     - constructing Foo
C0     - inside Foo
C0     } // Foo::Foo()
C0   + Foo::my_public() { #1
C0     - a=100
C0     - hello my_public
C0     + Foo::my_private() { #1
C0       - a=101
C0       + baz() { #5
C0         - a=103
C0         - return r=104
C0         } // baz()
C0       - return r=104
C0       } // Foo::my_private()
C0     - return r=104
C0     } // Foo::my_public()
C0   + baz() { #6
C0     - a=105
C0     - return r=106
C0     } // baz()
C0   - return b=106
C0   + Foo::~Foo() { #1
C0     - deconstructing Foo
C0     - inside ~Foo
C0     + my_struct::~my_struct() { #1
C0       - deconstructing my_struct; f_=my_struct_3
C0       } // my_struct::~my_struct()
C0     } // Foo::~Foo()
C0   + Foo::~Foo() { #2
C0     - deconstructing Foo
C0     - inside ~Foo
C0     + my_struct::~my_struct() { #2
C0       - deconstructing my_struct; f_=my_struct_3
C0       } // my_struct::~my_struct()
C0     } // Foo::~Foo()
C0   + my_struct::~my_struct() { #3
C0     - deconstructing my_struct; f_=my_struct_2
C0     } // my_struct::~my_struct()
C0   + clean_up() { #1
C0     - my_int=5
C0     } // clean_up()
C0   } // main()
C0 + bye_baz() { #1
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #2
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #3
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye() { #1
C0   - called via atexit() via main()
C0   } // bye()
C0 + bye_baz() { #4
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #5
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #6
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + my_struct::~my_struct() { #4
C0   - deconstructing my_struct; f_=my_struct_2
C0   } // my_struct::~my_struct()
C0 + my_struct::~my_struct() { #5
C0   - deconstructing my_struct; f_=my_struct_1
C0   } // my_struct::~my_struct()
C0 + cwrap_log_stats() { #1
C0   - [cwrap_log_stats() ignores verbosity!]
C0   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
C0   - 2 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
C0   - 1 calls to 1 of 1 function variation for main()
C0   - 5 calls to 1 of 1 function variation for my_struct::~my_struct()
C0   - 2 calls to 2 of 2 function variation for my_struct::my_struct()
C0   - 3 calls to 1 of 2 function variation for my_struct::my_struct()
C0   - 2 calls to 1 of 1 function variation for Foo::~Foo()
C0   - 2 calls to 1 of 1 function variation for Foo::Foo()
C0   - 1 calls to 1 of 1 function variation for Foo::my_public()
C0   - 1 calls to 1 of 1 function variation for Foo::my_private()
C0   - 3 calls to 1 of 1 function variation for quux()
C0   - 1 calls to 1 of 1 function variation for qux()
C0   - 1 calls to 1 of 1 function variation for bar()
C0   - 1 calls to 1 of 1 function variation for clean_up()
C0   - 1 calls to 1 of 1 function variation for int get_max<>()
C0   - 1 calls to 1 of 1 function variation for char get_max<>()
C0   - 6 calls to 1 of 1 function variation for bye_baz()
C0   - 2 calls to 1 of 1 function variation for __static_initialization_and_destruction_0()
C0   - 1 calls to 1 of 1 function variation for bye()
C0   - 6 calls to 1 of 1 function variation for baz()
C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_cpp_example_1_b_cpp()
C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_cpp_example_1_a_cpp()
C0   - 45 calls to 22 of 24 functions instrumented
C0   } // cwrap_log_stats()
```

- This 2nd run in `run.log` uses `CWRAP_LOG_VERBOSITY_SET=9:1=FUNCTION~my_` to dynamically disable all instrumented functions except for functions with names containing the text `my_`.
```
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=9:1=FUNCTION~my_ (<verbosity>[={file|function}~<keyword>][:...]) _STATS=1 _SHOW=0 _CURT=0 _FILE=0 _NUM=0 _COR_ID=1 _THREAD_ID=0 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
C0 + cwrap_log_verbosity_set() { #1
C0   - verbosity=9:1=FUNCTION~my_
C0   - [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 9 set for 24 matches in 24 functions for 1 byte clause '9' // type=FILE|FUNCTION keyword=(null)
C0   - verbosity 1 set for 5 matches in 24 functions for 14 byte clause '1=FUNCTION~my_' // type=FUNCTION keyword=my_
C0   } // cwrap_log_verbosity_set()
C0 + my_struct::my_struct() { #1
C0   - arg1=my_struct_1
C0   - constructing my_struct
C0   } // my_struct::my_struct()
C0 + my_struct::my_struct() { #2
C0   - arg1=my_struct_2
C0   - constructing my_struct
C0   } // my_struct::my_struct()
C0 + cwrap_log_verbosity_set() { #2
C0   - verbosity=2=function~bar
C0   - [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 2 set for 1 matches in 24 functions for 14 byte clause '2=function~bar' // type=FUNCTION keyword=bar
C0   } // cwrap_log_verbosity_set()
C0 + my_struct::my_struct() { #3
C0   - arg1=my_struct_2
C0   - constructing my_struct
C0   } // my_struct::my_struct()
C0 + my_struct::my_struct() { #1
C0   - arg1=my_struct_3, arg2=a
C0   - constructing my_struct
C0   } // my_struct::my_struct()
C0 + my_struct::my_struct() { #2
C0   - arg1=my_struct_3, arg2=b
C0   - constructing my_struct
C0   } // my_struct::my_struct()
C0 + Foo::my_public() { #1
C0   - a=100
C0   - hello my_public
C0   + Foo::my_private() { #1
C0     - a=101
C0     - return r=104
C0     } // Foo::my_private()
C0   - return r=104
C0   } // Foo::my_public()
C0 + my_struct::~my_struct() { #1
C0   - deconstructing my_struct; f_=my_struct_3
C0   } // my_struct::~my_struct()
C0 + my_struct::~my_struct() { #2
C0   - deconstructing my_struct; f_=my_struct_3
C0   } // my_struct::~my_struct()
C0 + my_struct::~my_struct() { #3
C0   - deconstructing my_struct; f_=my_struct_2
C0   } // my_struct::~my_struct()
C0 + my_struct::~my_struct() { #4
C0   - deconstructing my_struct; f_=my_struct_2
C0   } // my_struct::~my_struct()
C0 + my_struct::~my_struct() { #5
C0   - deconstructing my_struct; f_=my_struct_1
C0   } // my_struct::~my_struct()
C0 + cwrap_log_stats() { #1
C0   - [cwrap_log_stats() ignores verbosity!]
C0   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
C0   - 2 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
C0   - 5 calls to 1 of 1 function variation for my_struct::~my_struct()
C0   - 2 calls to 2 of 2 function variation for my_struct::my_struct()
C0   - 3 calls to 1 of 2 function variation for my_struct::my_struct()
C0   - 1 calls to 1 of 1 function variation for Foo::my_public()
C0   - 1 calls to 1 of 1 function variation for Foo::my_private()
C0   } // cwrap_log_stats()
```

- This 3rd run in `run.log` uses `CWRAP_LOG__QUIET_UNTIL=bye_baz` to dynamically disable all instrumented function until the function `bye_baz()` starts executing.
```
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}~<keyword>][:...]) _STATS=1 _SHOW=0 _CURT=0 _FILE=0 _NUM=0 _COR_ID=1 _THREAD_ID=0 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=bye_baz
C0 + cwrap_log_verbosity_set() { #1
C0   - verbosity=1
C0   - [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 1 set for 24 matches in 24 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
C0   } // cwrap_log_verbosity_set()
C0 + cwrap_log_quiet_until() { #1
C0   - name=bye_baz
C0   - going quiet until function bye_baz()
C0   -  [cwrap_log_quiet_until() ignores verbosity!]
C0   } // cwrap_log_quiet_until()
C0 + cwrap_log_verbosity_set() { #2
C0   - verbosity=2=function~bar
C0   - [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 2 set for 1 matches in 24 functions for 14 byte clause '2=function~bar' // type=FUNCTION keyword=bar
C0   } // cwrap_log_verbosity_set()
C0 + bye_baz() { #1
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #2
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #3
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye() { #1
C0   - called via atexit() via main()
C0   } // bye()
C0 + bye_baz() { #4
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #5
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + bye_baz() { #6
C0   - called via atexit() via baz()
C0   } // bye_baz()
C0 + my_struct::~my_struct() { #1
C0   - deconstructing my_struct; f_=my_struct_2
C0   } // my_struct::~my_struct()
C0 + my_struct::~my_struct() { #2
C0   - deconstructing my_struct; f_=my_struct_1
C0   } // my_struct::~my_struct()
C0 + cwrap_log_stats() { #1
C0   - [cwrap_log_stats() ignores verbosity!]
C0   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
C0   - 2 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
C0   - 1 calls to 1 of 1 function variation for cwrap_log_quiet_until()
C0   - 2 calls to 1 of 1 function variation for my_struct::~my_struct()
C0   - 6 calls to 1 of 1 function variation for bye_baz()
C0   - 1 calls to 1 of 1 function variation for bye()
C0   - 13 calls to 6 of 24 functions instrumented
C0   } // cwrap_log_stats()
```

- This is the same cwrap output but using the cwrap 'curt' output mode which can fold output onto a single line:
- The folding causes about half the number of output lines to be generated; human friendlier to read:
```
$ cat build/language-cpp-example-1-cwrap-include-long-make-via-n-line-opt-O3/run.log | wc -l
299
$ cat build/language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O3/run.log | wc -l
153
```

```
$ cat build/language-cpp-example-1-cwrap-include-curt-make-via-n-line-opt-O3/run.log
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}~<keyword>][:...]) _STATS=1 _SHOW=0 _CURT=1 _FILE=0 _NUM=0 _COR_ID=1 _THREAD_ID=0 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
C0 + cwrap_log_verbosity_set(verbosity=1) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 1 set for 24 matches in 24 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
C0   } // cwrap_log_verbosity_set()
C0 + _GLOBAL__sub_I_cpp_example_1_a_cpp() { // #1
C0   + __static_initialization_and_destruction_0() { // #1
C0     + my_struct::my_struct(arg1=my_struct_1) {} // #1 constructing my_struct
C0     } // __static_initialization_and_destruction_0()
C0   } // _GLOBAL__sub_I_cpp_example_1_a_cpp()
C0 + _GLOBAL__sub_I_cpp_example_1_b_cpp() { // #1
C0   + __static_initialization_and_destruction_0() { // #2
C0     + my_struct::my_struct(arg1=my_struct_2) {} // #2 constructing my_struct
C0     } // __static_initialization_and_destruction_0()
C0   } // _GLOBAL__sub_I_cpp_example_1_b_cpp()
C0 + main() { // #1
C0   + qux() { // #1
C0     + quux() {} = r=2 // #1
C0     + quux() {} = r=3 // #2
C0     + quux() {} = r=4 // #3
C0     } // qux()
C0   + bar(a=0) { // #1
C0     + baz(a=1) {} = r=2 // #1
C0     } = r=2 // bar()
C0   + cwrap_log_verbosity_set(verbosity=2=function~bar) { // #2 [cwrap_log_verbosity_set() ignores verbosity!]
C0     - verbosity 2 set for 1 matches in 24 functions for 14 byte clause '2=function~bar' // type=FUNCTION keyword=bar
C0     } // cwrap_log_verbosity_set()
C0   + baz(a=2) {} = r=3 // #2
C0   + baz(a=3) {} = r=4 // #3
C0   - hello world
C0   + baz(a=1) {} = r=2 // #4
C0   + int get_max<>(a=12345, b=67890) {} = r=67890 // #1
C0   + char get_max<>(a=43, b=21) {} = r=43 // #1
C0   + my_struct::my_struct(arg1=my_struct_2) {} // #3 constructing my_struct
C0   + Foo::Foo() { // #1
C0     + my_struct::my_struct(arg1=my_struct_3, arg2=a) {} // #1 constructing my_struct
C0     - constructing Foo
C0     - inside Foo
C0     } // Foo::Foo()
C0   + Foo::Foo() { // #2
C0     + my_struct::my_struct(arg1=my_struct_3, arg2=b) {} // #2 constructing my_struct
C0     - constructing Foo
C0     - inside Foo
C0     } // Foo::Foo()
C0   + Foo::my_public(a=100) { // #1
C0     - hello my_public
C0     + Foo::my_private(a=101) { // #1
C0       + baz(a=103) {} = r=104 // #5
C0       } = r=104 // Foo::my_private()
C0     } = r=104 // Foo::my_public()
C0   + baz(a=105) {} = r=106 // #6
C0   - return b=106
C0   + Foo::~Foo() { // #1 deconstructing Foo
C0     - inside ~Foo
C0     + my_struct::~my_struct() {} // #1 deconstructing my_struct; f_=my_struct_3
C0     } // Foo::~Foo()
C0   + Foo::~Foo() { // #2 deconstructing Foo
C0     - inside ~Foo
C0     + my_struct::~my_struct() {} // #2 deconstructing my_struct; f_=my_struct_3
C0     } // Foo::~Foo()
C0   + my_struct::~my_struct() {} // #3 deconstructing my_struct; f_=my_struct_2
C0   + clean_up() {} // #1 my_int=5
C0   } // main()
C0 + bye_baz() {} // #1 called via atexit() via baz()
C0 + bye_baz() {} // #2 called via atexit() via baz()
C0 + bye_baz() {} // #3 called via atexit() via baz()
C0 + bye() {} // #1 called via atexit() via main()
C0 + bye_baz() {} // #4 called via atexit() via baz()
C0 + bye_baz() {} // #5 called via atexit() via baz()
C0 + bye_baz() {} // #6 called via atexit() via baz()
C0 + my_struct::~my_struct() {} // #4 deconstructing my_struct; f_=my_struct_2
C0 + my_struct::~my_struct() {} // #5 deconstructing my_struct; f_=my_struct_1
C0 + cwrap_log_stats() { // #1 [cwrap_log_stats() ignores verbosity!]
C0   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
C0   - 2 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
C0   - 1 calls to 1 of 1 function variation for main()
C0   - 5 calls to 1 of 1 function variation for my_struct::~my_struct()
C0   - 2 calls to 2 of 2 function variation for my_struct::my_struct()
C0   - 3 calls to 1 of 2 function variation for my_struct::my_struct()
C0   - 2 calls to 1 of 1 function variation for Foo::~Foo()
C0   - 2 calls to 1 of 1 function variation for Foo::Foo()
C0   - 1 calls to 1 of 1 function variation for Foo::my_public()
C0   - 1 calls to 1 of 1 function variation for Foo::my_private()
C0   - 3 calls to 1 of 1 function variation for quux()
C0   - 1 calls to 1 of 1 function variation for qux()
C0   - 1 calls to 1 of 1 function variation for bar()
C0   - 1 calls to 1 of 1 function variation for clean_up()
C0   - 1 calls to 1 of 1 function variation for int get_max<>()
C0   - 1 calls to 1 of 1 function variation for char get_max<>()
C0   - 6 calls to 1 of 1 function variation for bye_baz()
C0   - 2 calls to 1 of 1 function variation for __static_initialization_and_destruction_0()
C0   - 1 calls to 1 of 1 function variation for bye()
C0   - 6 calls to 1 of 1 function variation for baz()
C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_cpp_example_1_b_cpp()
C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_cpp_example_1_a_cpp()
C0   - 45 calls to 22 of 24 functions instrumented
C0   } // cwrap_log_stats()
```
- This 2nd run in `run.log` -- with cwrap 'curt' output -- uses `CWRAP_LOG_VERBOSITY_SET=9:1=FUNCTION~my_` to dynamically disable all instrumented functions except for functions with names containing the text `my_`.
```
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=9:1=FUNCTION~my_ (<verbosity>[={file|function}~<keyword>][:...]) _STATS=1 _SHOW=0 _CURT=1 _FILE=0 _NUM=0 _COR_ID=1 _THREAD_ID=0 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=(null)
C0 + cwrap_log_verbosity_set(verbosity=9:1=FUNCTION~my_) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 9 set for 24 matches in 24 functions for 1 byte clause '9' // type=FILE|FUNCTION keyword=(null)
C0   - verbosity 1 set for 5 matches in 24 functions for 14 byte clause '1=FUNCTION~my_' // type=FUNCTION keyword=my_
C0   } // cwrap_log_verbosity_set()
C0 + my_struct::my_struct(arg1=my_struct_1) {} // #1 constructing my_struct
C0 + my_struct::my_struct(arg1=my_struct_2) {} // #2 constructing my_struct
C0 + cwrap_log_verbosity_set(verbosity=2=function~bar) { // #2 [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 2 set for 1 matches in 24 functions for 14 byte clause '2=function~bar' // type=FUNCTION keyword=bar
C0   } // cwrap_log_verbosity_set()
C0 + my_struct::my_struct(arg1=my_struct_2) {} // #3 constructing my_struct
C0 + my_struct::my_struct(arg1=my_struct_3, arg2=a) {} // #1 constructing my_struct
C0 + my_struct::my_struct(arg1=my_struct_3, arg2=b) {} // #2 constructing my_struct
C0 + Foo::my_public(a=100) { // #1
C0   - hello my_public
C0   + Foo::my_private(a=101) {} = r=104 // #1
C0   } = r=104 // Foo::my_public()
C0 + my_struct::~my_struct() {} // #1 deconstructing my_struct; f_=my_struct_3
C0 + my_struct::~my_struct() {} // #2 deconstructing my_struct; f_=my_struct_3
C0 + my_struct::~my_struct() {} // #3 deconstructing my_struct; f_=my_struct_2
C0 + my_struct::~my_struct() {} // #4 deconstructing my_struct; f_=my_struct_2
C0 + my_struct::~my_struct() {} // #5 deconstructing my_struct; f_=my_struct_1
C0 + cwrap_log_stats() { // #1 [cwrap_log_stats() ignores verbosity!]
C0   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
C0   - 2 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
C0   - 5 calls to 1 of 1 function variation for my_struct::~my_struct()
C0   - 2 calls to 2 of 2 function variation for my_struct::my_struct()
C0   - 3 calls to 1 of 2 function variation for my_struct::my_struct()
C0   - 1 calls to 1 of 1 function variation for Foo::my_public()
C0   - 1 calls to 1 of 1 function variation for Foo::my_private()
C0   } // cwrap_log_stats()
```

- This 3rd run in `run.log` -- with cwrap 'curt' output -- uses `CWRAP_LOG__QUIET_UNTIL=bye_baz` to dynamically disable all instrumented function until the function `bye_baz()` starts executing.
```
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}~<keyword>][:...]) _STATS=1 _SHOW=0 _CURT=1 _FILE=0 _NUM=0 _COR_ID=1 _THREAD_ID=0 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0 _QUIET_UNTIL=bye_baz
C0 + cwrap_log_verbosity_set(verbosity=1) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 1 set for 24 matches in 24 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
C0   } // cwrap_log_verbosity_set()
C0 + cwrap_log_quiet_until(name=bye_baz) {} // #1 going quiet until function bye_baz() [cwrap_log_quiet_until() ignores verbosity!]
C0 + cwrap_log_verbosity_set(verbosity=2=function~bar) { // #2 [cwrap_log_verbosity_set() ignores verbosity!]
C0   - verbosity 2 set for 1 matches in 24 functions for 14 byte clause '2=function~bar' // type=FUNCTION keyword=bar
C0   } // cwrap_log_verbosity_set()
C0 + bye_baz() {} // #1 called via atexit() via baz()
C0 + bye_baz() {} // #2 called via atexit() via baz()
C0 + bye_baz() {} // #3 called via atexit() via baz()
C0 + bye() {} // #1 called via atexit() via main()
C0 + bye_baz() {} // #4 called via atexit() via baz()
C0 + bye_baz() {} // #5 called via atexit() via baz()
C0 + bye_baz() {} // #6 called via atexit() via baz()
C0 + my_struct::~my_struct() {} // #1 deconstructing my_struct; f_=my_struct_2
C0 + my_struct::~my_struct() {} // #2 deconstructing my_struct; f_=my_struct_1
C0 + cwrap_log_stats() { // #1 [cwrap_log_stats() ignores verbosity!]
C0   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
C0   - 2 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
C0   - 1 calls to 1 of 1 function variation for cwrap_log_quiet_until()
C0   - 2 calls to 1 of 1 function variation for my_struct::~my_struct()
C0   - 6 calls to 1 of 1 function variation for bye_baz()
C0   - 1 calls to 1 of 1 function variation for bye()
C0   - 13 calls to 6 of 24 functions instrumented
C0   } // cwrap_log_stats()
```
