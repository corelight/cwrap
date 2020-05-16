How to cwrap Zeek
=========================

Example of how a newbie can cwrap auto instrument the Zeek codebase to learn more about it.

Cloning and compiling
-----------
Install [Zeek prerequisites](https://docs.zeek.org/en/stable/install/install.html#prerequisites), and clone cwrap and Zeek:
```
$ sudo apt-get install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev ninja-build # install prerequisites$ git clone https://github.com/corelight/cwrap.git
$ pushd cwrap/test/ ; perl cwrap-test.pl ; popd
$ time git clone --recursive --branch v3.1.2 --single-branch https://github.com/zeek/zeek.git
real    0m37.318s
$ cd zeek/
```
Compile Zeek *without* cwrap:
```
$ make distclean && ./configure --build-type=Debug --enable-debug
$ time make -j`nproc` 2>&1 | egrep --line-buffered -v "(Entering|Leaving)" | tee ./build/make-j`nproc`.log
...
[100%] Built target zeek
real    5m10.279s
$ wc --bytes build/src/zeek
213,586,792 build/src/zeek
```
Compile Zeek *with* cwrap:
```
$ make distclean && CC=`pwd`/../cwrap/cwrap.pl CXX=$CC ./configure --build-type=Debug --enable-debug
$ time make -j`nproc` 2>&1 | egrep --line-buffered -v "(Entering|Leaving)" | tee ./build/make-j`nproc`.log
...
[100%] Built target zeek
real    6m55.067s
$ wc --bytes build/src/zeek
277,448,936 build/src/zeek
$ cat ./build/make-j16.log | wc -l
1,725
```
Examining cwrap build-time logs
-----------
cwrap creates a log file for each Zeek file compiled or linked:
```
$ find build/ -type f | egrep ".cwrap.log" | wc -l
937
```
Which files are slowest to compile from source to assembler?
```
$ find build -type f | egrep ".cwrap.log" | xargs egrep "seconds building assembler for" | perl -lane '$c++; s~^build/.* in ~~; if(m~^([\.\d]+) (.*)~){ $c++; $st+=$1; push @lines, sprintf qq[%12.6f %s], $1, $2; } sub END{ foreach(sort @lines){ printf qq[%s\n],$_; } printf qq[- %d files built in %f seconds, or average %f seconds per file\n], $c, $st, $st / $c; }' | tail
   27.063574 seconds building assembler for CMakeFiles/broker-test.dir/cpp/integration.cc.o
   28.635410 seconds building assembler for CMakeFiles/broker.dir/src/detail/core_policy.cc.o
   29.717507 seconds building assembler for CMakeFiles/broker.dir/src/configuration.cc.o
   32.565119 seconds building assembler for CMakeFiles/_broker.dir/data.cpp.o
   32.741941 seconds building assembler for CMakeFiles/libcaf_io_shared.dir/src/io/middleman.cpp.o
   35.059298 seconds building assembler for CMakeFiles/broker-cluster-benchmark.dir/benchmark/broker-cluster-benchmark.cc.o
   37.041866 seconds building assembler for CMakeFiles/broker.dir/src/core_actor.cc.o
   39.285644 seconds building assembler for CMakeFiles/broker-test.dir/cpp/core.cc.o
   51.068612 seconds building assembler for CMakeFiles/_broker.dir/_broker.cpp.o
- 912 files built in 4221.948949 seconds, or average 4.629330 seconds per file
```
Which files are slowest to compile from assembler to object?
```
$ find build -type f | egrep ".cwrap.log" | xargs egrep "seconds building object or shared object for" | perl -lane '$c++; s~^build/.* in ~~; if(m~^([\.\d]+) (.*)~){ $st+=$1; push @lines, sprintf qq[%12.6f %s], $1, $2; } sub END{ foreach(sort @lines){ printf qq[%s\n],$_; } printf qq[- %d files built in %f seconds, or average %f seconds per file\n], $c, $st, $st / $c; }' | tail
    3.799946 seconds building object or shared object for CMakeFiles/broker-test.dir/cpp/master.cc.o
    4.415592 seconds building object or shared object for lib/libbroker.so.1.3
    5.035691 seconds building object or shared object for CMakeFiles/libcaf_io_shared.dir/src/io/middleman.cpp.o
    5.425663 seconds building object or shared object for /home/simon/20200425-cwrap-zeek/official/zeek/build/aux/broker/lib/libcaf_core.so.0.17.4
    5.439404 seconds building object or shared object for CMakeFiles/_broker.dir/data.cpp.o
    5.635249 seconds building object or shared object for CMakeFiles/broker-test.dir/cpp/core.cc.o
    5.842214 seconds building object or shared object for CMakeFiles/broker-cluster-benchmark.dir/benchmark/broker-cluster-benchmark.cc.o
    5.861471 seconds building object or shared object for ../../python/broker/_broker.so
    7.524167 seconds building object or shared object for CMakeFiles/_broker.dir/_broker.cpp.o
- 919 files built in 329.007359 seconds, or average 0.358006 seconds per file
```
Which binaries are slowest to link?
```
$ find build -type f | egrep ".cwrap.log" | xargs egrep "seconds building binary for" | perl -lane '$c++; s~^build/.* in ~~; if(m~^([\.\d]+) (.*)~){ $st+=$1; push @lines, sprintf qq[%12.6f %s], $1, $2; } sub END{ foreach(sort @lines){ printf qq[%s\n],$_; } printf qq[- %d files built in %f seconds, or average %f seconds per file\n], $c, $st, $st / $c; }' | tail
    2.025140 seconds building binary for ../../bin/synopsis
    2.036102 seconds building binary for bin/broker-pipe
    2.051074 seconds building binary for ../../bin/ping
    2.100260 seconds building binary for ../../bin/comm
    2.125164 seconds building binary for ../../bin/stores
    2.197867 seconds building binary for bin/broker-node
    2.243052 seconds building binary for ../bin/broker-benchmark
    2.330137 seconds building binary for ../bin/broker-cluster-benchmark
    4.553935 seconds building binary for zeek
- 18 files built in 24.898997 seconds, or average 1.383278 seconds per file
```
How many `__cyg_profile_func_enter()` and `__cyg_profile_func_exit()` calls were modified?
```
$ find build/ -type f | egrep ".s.2.s$" | xargs egrep "__cyg_profile_func_(enter|exit)" | wc -l
930,909
$ find build/ -type f | egrep ".s.2.s$" | xargs egrep "__cyg_profile_func_enter" | wc -l
393,296
$ find build/ -type f | egrep ".s.2.s$" | xargs egrep "__cyg_profile_func_exit" | wc -l
537,613
```
How many function names did cwrap deal with?
- In this example, there are 109,535 unique mangled and demangled function names.
- However, many demangled names are prohibitively long and even 100s of KB long.
- So cwrap creates a skeletonized generic version of the demangled name which is must shorter but non-unique.
- In this example, the 109,535 unique functions, reduce to 23,663 skeletonized generic function names.
- If you added up all the bytes in the 109,535 unique mangled names, then this would be 14,418,984 bytes.
- If you added up all the bytes in the 109,535 unique demangled names, then this would be 50,576,392 bytes.
- If you added up all the bytes in the 23,633 skeletonized generic function names, then this would be 854,989 bytes.
- Note: Unfortunately no 100% reliable tools exist for demangling all the mangled C++ names; please see [this link](https://gist.github.com/simonhf/0d60bb94f2d90c1b32e4786b2d1062ad) for the basis of [gcc](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=93035) and [clang](https://bugs.llvm.org/show_bug.cgi?id=44428) bug [tickets](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=93475).
```
$ cat build/src/zeek.cwrap.log | egrep _names=
15.355935   - cwrap: number___mangled_names=109,535
15.355949   - cwrap: number_demangled_names=109,535
15.355950   - cwrap: number___generic_names=23,663
15.355951   - cwrap:  bytes___mangled_names=14,418,984
15.355953   - cwrap:  bytes_demangled_names=50,576,392
15.355954   - cwrap:  bytes___generic_names=854,989
```
How many lines of code of C/C++ are there compared to assembler?
```
$ find . -type f | egrep "(\.cxx|\.cpp|\.cc|\.c|\.h|\.hpp)$" | egrep -v "(cwrap|/build|/test)" | xargs --max-args=1 wc -l | perl -lane 'if(m~(\d+)~){$t+=$1} sub END{ printf qq[- total source lines: %d\n],$t; }'
- total source lines: 1,051,024
$ find . -type f | egrep "\.s\.2\.s" | xargs --max-args=1 wc -l | perl -lane 'if(m~(\d+)~){$t+=$1} sub END{ printf qq[- total assembler lines: %d\n],$t; }'
- total assembler lines: 177,440,504
```

Examining cwrap build-time source files
-----------
One `cwrap.c` file is auto generated at build-time per executable linked:
```
$ find build -type f | egrep "\.cwrap\.c$" | egrep -v "\.so" | xargs wc -l
      973 build/aux/bifcl/bifcl.cwrap.c
    75223 build/aux/broker/tests/broker-cluster-benchmark.cwrap.c
    86175 build/aux/broker/tests/broker-test.cwrap.c
    72571 build/aux/broker/tests/broker-benchmark.cwrap.c
    44622 build/aux/broker/caf-build/doc/caf-generate-rst.cwrap.c
    72118 build/aux/broker/doc/_examples/ping.cwrap.c
    72126 build/aux/broker/doc/_examples/comm.cwrap.c
    72008 build/aux/broker/doc/_examples/synopsis.cwrap.c
    71979 build/aux/broker/doc/_examples/stores.cwrap.c
    73349 build/aux/broker/broker-node.cwrap.c
    72371 build/aux/broker/broker-pipe.cwrap.c
     3257 build/aux/binpac/src/binpac.cwrap.c
      818 build/aux/zeek-aux/zeek-cut/zeek-cut.cwrap.c
      818 build/aux/zeek-aux/rst/rst.cwrap.c
      814 build/aux/zeek-aux/adtrace/adtrace.cwrap.c
     1601 build/aux/paraglob/tools/paraglob-test.cwrap.c
      833 build/aux/zeekctl/aux/capstats/capstats.cwrap.c
   110340 build/src/zeek.cwrap.c
```
Each `cwrap.c` file contains one `CWRAP_DATA_*` declaration per instrumented function, including its current verbosity, its skeletonized generic name (including x of y variant info), and where it comes from:
```
$ cat build/src/zeek.cwrap.c | egrep "CWRAP_DATA cwrap_data_" | perl -lane '$fc ++; s~^CWRAP_DATA cwrap_data_.* = \{9, CWRAP_MAGIC, 0, ~~; s~, \&[^\}]+\};~~; @f=split(m~, ~, $_); if(1){printf qq[@f\n];}' | head
1 1 14 14 "Clear_Patricia" 14 "CMakeFiles/zeek.dir/patricia.c.o" 32 NULL NULL};
1 1 19 19 "ConvertUTF16toUTF32" 19 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 18 18 "ConvertUTF16toUTF8" 18 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 19 19 "ConvertUTF32toUTF16" 19 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 18 18 "ConvertUTF32toUTF8" 18 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 18 18 "ConvertUTF8toUTF16" 18 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 18 18 "ConvertUTF8toUTF32" 18 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 22 22 "ConvertUTF8toUTF32Impl" 22 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 25 25 "ConvertUTF8toUTF32Partial" 25 "CMakeFiles/zeek.dir/ConvertUTF.c.o" 34 NULL
1 1 12 12 "Deref_Prefix" 12 "CMakeFiles/zeek.dir/patricia.c.o" 32 NULL
```
For example, the function `caf::detail::tuple_inspect_delegate<>` has 5,600 variants, and we can see that most of the 109,535 unique functions in Zeek are variations of the same function, with only 23,663 unique skeleton functions:
```
$ cat build/src/zeek.cwrap.c | egrep "CWRAP_DATA cwrap_data_" | perl -lane '$fc ++; s~^CWRAP_DATA cwrap_data_.* = \{9, CWRAP_MAGIC, 0, ~~; s~, \&[^\}]+\};~~; @f=split(m~, ~, $_); if(0){printf qq[@f\n];} $of_y=sprintf qq[%07d %s],$f[1], $f[4]; $v->{$of_y} = 1; sub END{ foreach(sort keys %{$v}){ printf qq[- variations for skeleton: %s\n], $_; } printf qq[- %d total unique functions instrumented, and %d unique skeleton functions\n], $fc, scalar keys %{$v}; }' | tail
- variations for skeleton: 0000819 "caf::visit_impl_continuation<>::operator()<>"
- variations for skeleton: 0000840 "caf::visit_impl<>::apply<>"
- variations for skeleton: 0000882 "std::_Tuple_impl<>::_Tuple_impl<>"
- variations for skeleton: 0000895 "caf::detail::tuple_vals_impl<>::dispatch<>"
- variations for skeleton: 0000895 "caf::detail::tuple_vals_impl<>::rec_dispatch<>"
- variations for skeleton: 0000947 "std::_Tuple_impl<>::_M_head"
- variations for skeleton: 0001093 "std::tuple_element<>::std::get<>"
- variations for skeleton: 0001286 "std::remove_reference<>::std::move<>"
- variations for skeleton: 0005600 "caf::detail::tuple_inspect_delegate<>"
- 109535 total unique functions instrumented, and 23663 unique skeleton functions
```
Mangled C++ names can be long, for example, the skeletonized function name `caf::make_counted<>` has 315 variants of which the variant number 247 is the biggest mangled name of 2,927 bytes long:
```
$ cat build/src/zeek.cwrap.c | egrep "CWRAP_DATA cwrap_data_" | perl -lane '$fc ++; s~^CWRAP_DATA cwrap_data_.* = \{9, CWRAP_MAGIC, 0, ~~; s~, \&[^\}]+\};~~; @f=split(m~, ~, $_); if(0){printf qq[@f\n];} $name = sprintf qq[%04d mangled bytes (%06d demangled bytes) for variaton %4d of %4d %s], $f[2], $f[3], $f[0],$f[1], $f[4]; push @names, $name; sub END{ foreach(sort @names){ printf qq[- %s\n],$_; } }' | tail
- 2806 mangled bytes (029772 demangled bytes) for variaton   41 of  272 "caf::detail::default_behavior_impl<>::init<>"
- 2806 mangled bytes (029772 demangled bytes) for variaton   42 of  272 "caf::detail::default_behavior_impl<>::init<>"
- 2806 mangled bytes (029772 demangled bytes) for variaton   43 of  272 "caf::detail::default_behavior_impl<>::init<>"
- 2806 mangled bytes (029772 demangled bytes) for variaton   45 of  272 "caf::detail::default_behavior_impl<>::init<>"
- 2806 mangled bytes (029772 demangled bytes) for variaton   46 of  272 "caf::detail::default_behavior_impl<>::init<>"
- 2806 mangled bytes (029772 demangled bytes) for variaton   47 of  272 "caf::detail::default_behavior_impl<>::init<>"
- 2865 mangled bytes (071182 demangled bytes) for variaton  223 of  563 "std::tuple<>::tuple<>"
- 2877 mangled bytes (071199 demangled bytes) for variaton  168 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
- 2887 mangled bytes (071230 demangled bytes) for variaton    8 of   65 "caf::detail::default_behavior_impl<>::default_behavior_impl<>"
- 2927 mangled bytes (100550 demangled bytes) for variaton  247 of  315 "caf::make_counted<>"
```
Demangled C++ names can be longer, for example, the skeletonized function name `std::_Tuple_impl<>::_Tuple_impl<>` has 882 variants of which the variant number 864 is the biggest demangled name of 241,915 bytes long:
```
$ cat build/src/zeek.cwrap.c | egrep "CWRAP_DATA cwrap_data_" | perl -lane '$fc ++; s~^CWRAP_DATA cwrap_data_.* = \{9, CWRAP_MAGIC, 0, ~~; s~, \&[^\}]+\};~~; @f=split(m~, ~, $_); if(0){printf qq[@f\n];} $name = sprintf qq[%06d demangled bytes (%4d mangled bytes) for variation %4d of %4d %s], $f[3], $f[2], $f[0],$f[1], $f[4]; push @names, $name; sub END{ foreach(sort @names){ printf qq[- %s\n],$_; } }' | tail
- 126108 demangled bytes (2416 mangled bytes) for variation  871 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
- 127122 demangled bytes (2684 mangled bytes) for variation  794 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
- 127337 demangled bytes (2083 mangled bytes) for variation  229 of  459 "caf::std::__get_helper<>"
- 128737 demangled bytes (2336 mangled bytes) for variation  448 of  459 "caf::std::__get_helper<>"
- 136180 demangled bytes (2205 mangled bytes) for variation  412 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
- 144944 demangled bytes (2530 mangled bytes) for variation  851 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
- 155726 demangled bytes (2148 mangled bytes) for variation  416 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
- 166829 demangled bytes (2606 mangled bytes) for variation  831 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
- 200007 demangled bytes (2388 mangled bytes) for variation  443 of  459 "caf::std::__get_helper<>"
- 241915 demangled bytes (2472 mangled bytes) for variation  864 of  882 "std::_Tuple_impl<>::_Tuple_impl<>"
```
Examining the longest demangled name:
- The mangled name is found in `cwrap.c`, and the output of both `c++filt` and `llvm-cxxfilt` are shown.
- Both tools 'disagree' about the demangled length, one saying 241,916 bytes, and the other only 30,183 bytes!
```
$ cat build/src/zeek.cwrap.c | egrep "CWRAP_DATA cwrap_data_" | egrep 241915 # find mangled name
CWRAP_DATA cwrap_data__ZNSt11_Tuple_implILm6EJN3caf18trivial_match_caseIZN6broker10core_actorEPNS0_14stateful_actorINS2_10core_stateENS0_17event_based_actorEEESt6vectorINS2_5topicESaIS9_EENS2_14broker_optionsEPNS2_8endpoint5clockEEUlRKNS0_6streamINS2_12node_messageEEERSB_RNS0_5actorEE6_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSK_NS0_13atom_constantILNS0_10atom_valueE64816EEESN_E7_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093969276522EEESB_E8_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_264194995EEESL_E9_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_E10_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_SN_E11_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_NSQ_ILSR_17060810218EEESL_E12_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_9cow_tupleIJS9_NS2_4dataEEEEEEE13_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_7variantIJS1A_NS18_IJS9_NS2_16internal_commandEEEEEEEEEE14_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_69675774307885EEERS1A_E15_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RS1G_E16_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_NSQ_ILSR_16942008753EEES1M_E17_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_S1S_S1P_E18_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RNS2_13endpoint_infoES1M_E19_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_1085131692727EEENSQ_ILSR_1072565742125EEERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEENS2_7backendERSt13unordered_mapIS28_S19_St4hashIS28_ESt8equal_toIS28_ESaISt4pairIS29_S19_EEEE20_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_16790277354EEES22_RS28_dddE21_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4471961654844729EEES2A_SN_E22_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4115129EEES2A_E23_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_69796319403754EEES2P_SN_E24_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_NSQ_ILSR_265726647EEEE25_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_S31_NSQ_ILSR_266578424EEEE26_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093938883255EEENS2_12network_infoEE27_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS37_SM_E28_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4450015542722168EEEE29_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4471570876026675EEEE30_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS3G_S15_E31_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4090473EEENSQ_ILSR_1091888193208EEESN_E32_EEEEC2ISO_JST_SW_SZ_S11_S13_S16_S1C_S1J_S1N_S1Q_S1T_S1V_S1Z_S2M_S2Q_S2T_S2W_S2Z_S32_S35_S39_S3B_S3E_S3H_S3J_S3N_EvEEOT_DpOT0_ = {9, CWRAP_MAGIC, 0, 864, 882, 2472, 241915, "std::_Tuple_impl<>::_Tuple_impl<>", 33, "../aux/broker/lib/libbroker.so.1.3", 34, NULL, &cwrap_data__ZNSt11_Tuple_implILm6EJN3caf18trivial_match_caseIZN6broker10core_actorEPNS0_14stateful_actorINS2_10core_stateENS0_17event_based_actorEEESt6vectorINS2_5topicESaIS9_EENS2_14broker_optionsEPNS2_8endpoint5clockEEUlRKNS0_6streamINS2_12node_messageEEERSB_RNS0_5actorEE6_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSK_NS0_13atom_constantILNS0_10atom_valueE64816EEESN_E7_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093969276522EEESB_E8_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_264194995EEESL_E9_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_E10_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_SN_E11_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_NSQ_ILSR_17060810218EEESL_E12_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_9cow_tupleIJS9_NS2_4dataEEEEEEE13_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_7variantIJS1A_NS18_IJS9_NS2_16internal_commandEEEEEEEEEE14_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_69675774307885EEERS1A_E15_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RS1G_E16_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_NSQ_ILSR_16942008753EEES1M_E17_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_S1S_S1P_E18_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RNS2_13endpoint_infoES1M_E19_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_1085131692727EEENSQ_ILSR_1072565742125EEERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEENS2_7backendERSt13unordered_mapIS28_S19_St4hashIS28_ESt8equal_toIS28_ESaISt4pairIS29_S19_EEEE20_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_16790277354EEES22_RS28_dddE21_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4471961654844729EEES2A_SN_E22_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4115129EEES2A_E23_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_69796319403754EEES2P_SN_E24_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_NSQ_ILSR_265726647EEEE25_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_S31_NSQ_ILSR_266578424EEEE26_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093938883255EEENS2_12network_infoEE27_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS37_SM_E28_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4450015542722168EEEE29_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4471570876026675EEEE30_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS3G_S15_E31_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4090473EEENSQ_ILSR_1091888193208EEESN_E32_EEEE7_M_headERS3P_};

$ c++filt --no-recursion-limit _ZNSt11_Tuple_implILm6EJN3caf18trivial_match_caseIZN6broker10core_actorEPNS0_14stateful_actorINS2_10core_stateENS0_17event_based_actorEEESt6vectorINS2_5topicESaIS9_EENS2_14broker_optionsEPNS2_8endpoint5clockEEUlRKNS0_6streamINS2_12node_messageEEERSB_RNS0_5actorEE6_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSK_NS0_13atom_constantILNS0_10atom_valueE64816EEESN_E7_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093969276522EEESB_E8_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_264194995EEESL_E9_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_E10_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_SN_E11_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_NSQ_ILSR_17060810218EEESL_E12_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_9cow_tupleIJS9_NS2_4dataEEEEEEE13_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_7variantIJS1A_NS18_IJS9_NS2_16internal_commandEEEEEEEEEE14_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_69675774307885EEERS1A_E15_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RS1G_E16_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_NSQ_ILSR_16942008753EEES1M_E17_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_S1S_S1P_E18_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RNS2_13endpoint_infoES1M_E19_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_1085131692727EEENSQ_ILSR_1072565742125EEERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEENS2_7backendERSt13unordered_mapIS28_S19_St4hashIS28_ESt8equal_toIS28_ESaISt4pairIS29_S19_EEEE20_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_16790277354EEES22_RS28_dddE21_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4471961654844729EEES2A_SN_E22_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4115129EEES2A_E23_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_69796319403754EEES2P_SN_E24_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_NSQ_ILSR_265726647EEEE25_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_S31_NSQ_ILSR_266578424EEEE26_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093938883255EEENS2_12network_infoEE27_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS37_SM_E28_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4450015542722168EEEE29_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4471570876026675EEEE30_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS3G_S15_E31_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4090473EEENSQ_ILSR_1091888193208EEESN_E32_EEEEC2ISO_JST_SW_SZ_S11_S13_S16_S1C_S1J_S1N_S1Q_S1T_S1V_S1Z_S2M_S2Q_S2T_S2W_S2Z_S32_S35_S39_S3B_S3E_S3H_S3J_S3N_EvEEOT_DpOT0_ | wc --bytes
241,916

$ llvm-cxxfilt _ZNSt11_Tuple_implILm6EJN3caf18trivial_match_caseIZN6broker10core_actorEPNS0_14stateful_actorINS2_10core_stateENS0_17event_based_actorEEESt6vectorINS2_5topicESaIS9_EENS2_14broker_optionsEPNS2_8endpoint5clockEEUlRKNS0_6streamINS2_12node_messageEEERSB_RNS0_5actorEE6_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSK_NS0_13atom_constantILNS0_10atom_valueE64816EEESN_E7_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093969276522EEESB_E8_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_264194995EEESL_E9_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_E10_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_SV_tSL_SN_E11_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlSY_NSQ_ILSR_17060810218EEESL_E12_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_9cow_tupleIJS9_NS2_4dataEEEEEEE13_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSG_INS0_7variantIJS1A_NS18_IJS9_NS2_16internal_commandEEEEEEEEEE14_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_69675774307885EEERS1A_E15_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RS1G_E16_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_NSQ_ILSR_16942008753EEES1M_E17_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_S1S_S1P_E18_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS1L_RNS2_13endpoint_infoES1M_E19_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_1085131692727EEENSQ_ILSR_1072565742125EEERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEENS2_7backendERSt13unordered_mapIS28_S19_St4hashIS28_ESt8equal_toIS28_ESaISt4pairIS29_S19_EEEE20_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_NSQ_ILSR_16790277354EEES22_RS28_dddE21_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4471961654844729EEES2A_SN_E22_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_4115129EEES2A_E23_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS15_S21_NSQ_ILSR_69796319403754EEES2P_SN_E24_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_NSQ_ILSR_265726647EEEE25_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS2V_S31_NSQ_ILSR_266578424EEEE26_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_1093938883255EEENS2_12network_infoEE27_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS37_SM_E28_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4450015542722168EEEE29_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4471570876026675EEEE30_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlS3G_S15_E31_EENS1_IZNS2_10core_actorES7_SB_SC_SF_EUlNSQ_ILSR_4090473EEENSQ_ILSR_1091888193208EEESN_E32_EEEEC2ISO_JST_SW_SZ_S11_S13_S16_S1C_S1J_S1N_S1Q_S1T_S1V_S1Z_S2M_S2Q_S2T_S2W_S2Z_S32_S35_S39_S3B_S3E_S3H_S3J_S3N_EvEEOT_DpOT0_ | wc --bytes
30,183
```

Running cwrap auto instrumented `zeek --help`
-----------
How many functions does Zeek embedded cwrap say are instrumented at run-time:
```
$ CWRAP_LOG_SHOW=1 ./build/src/zeek --help | tail
C0   - #109,527: verbosity 9 for 1 of 1 function variation for ConvertUTF8toUTF32Partial() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,528: verbosity 9 for 1 of 1 function variation for ConvertUTF8toUTF32Impl() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,529: verbosity 9 for 1 of 1 function variation for ConvertUTF8toUTF32() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,530: verbosity 9 for 1 of 1 function variation for ConvertUTF8toUTF16() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,531: verbosity 9 for 1 of 1 function variation for ConvertUTF32toUTF8() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,532: verbosity 9 for 1 of 1 function variation for ConvertUTF32toUTF16() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,533: verbosity 9 for 1 of 1 function variation for ConvertUTF16toUTF8() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,534: verbosity 9 for 1 of 1 function variation for ConvertUTF16toUTF32() from CMakeFiles/zeek.dir/ConvertUTF.c.o
C0   - #109,535: verbosity 9 for 1 of 1 function variation for Clear_Patricia() from CMakeFiles/zeek.dir/patricia.c.o
C0   } // cwrap_log_show()
```
Enable verbosity for all functions and run `zeek --help` to see what happens:
```
$ CWRAP_LOG_STATS=1 CWRAP_LOG_NUM=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_FILE=1 CWRAP_LOG_CURT=1 CWRAP_LOG_VERBOSITY_SET=1 ./build/src/zeek --help
zeek version 3.1.2-debug
usage: ./build/src/zeek [options] [file ...]
usage: ./build/src/zeek --test [doctest-options] -- [options] [file ...]
...
$ wc -l cwrap.out # number of lines of cwrap output
79,723 cwrap.out
$ head cwrap.out
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}-<keyword>][/...]) _QUIET_UNTIL=(null) _STATS=1 _SHOW=0 _CURT=1 _FILE=1 _NUM=1 _COR_ID=1 _THREAD_ID=1 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0
#1 T13115 C0 + cwrap_log_verbosity_set(verbosity=1) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
#2 T13115 C0   - verbosity 1 set for 109,535 matches in 109,535 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
#3 T13115 C0   } // cwrap_log_verbosity_set()
#4 T13115 C0 + _GLOBAL__sub_I_abstract_actor_cpp() { // #1
#5 T13115 C0   + __static_initialization_and_destruction_0() {} // #1
#6 T13115 C0   } // _GLOBAL__sub_I_abstract_actor_cpp()
#7 T13115 C0 + _GLOBAL__sub_I_abstract_channel_cpp() { // #1
#8 T13115 C0   + __static_initialization_and_destruction_0() {} // #2
#9 T13115 C0   } // _GLOBAL__sub_I_abstract_channel_cpp()
```
cwrap tries to be the first code to run so that it can capture all the static initialization before main() is called:
```
$ cat cwrap.out | egrep "\+ _GLOBAL__sub_I_" | wc -l # c/c++ files doing static initialization
337
$ cat cwrap.out | egrep "\+ main"
#66,927 T13115 C0 + main() { // #1
```
We asked cwrap to provide stats before process exit:
- Just before process exit, cwrap output stats on the 1,441 unique functions called form 109,535 possible functions.
- Note: cwrap tries to output stats last but it might be close to last as it's difficult to force code to run as the very last.
- In this case lines #79,591 to #79,722 of cwrap output contain a little more static destruction before exit.
```
$ egrep --after-context=10 "\+ cwrap_log_stats" cwrap.out
#78147 T13115 C0 + cwrap_log_stats() { // #1 [cwrap_log_stats() ignores verbosity!]
#78148 T13115 C0   - 1 calls to 1 of 1 function variation for cwrap_log_stats()
#78149 T13115 C0   - 1 calls to 1 of 1 function variation for cwrap_log_verbosity_set()
#78150 T13115 C0   - 1 calls to 1 of 1 function variation for main()
#78151 T13115 C0   - 1 calls to 1 of 1 function variation for __tcf_0()
#78152 T13115 C0   - 406 calls to 1 of 1 function variation for operator new()
#78153 T13115 C0   - 1 calls to 2 of 10 function variation for std::operator+<>()
#78154 T13115 C0   - 1 calls to 1 of 10 function variation for std::operator+<>()
#78155 T13115 C0   - 67 calls to 116 of 200 function variation for std::operator!=()
#78156 T13115 C0   - 1 calls to 25 of 200 function variation for std::operator!=()
#78157 T13115 C0   - 1,401 calls to 17 of 20 function variation for std::operator< <>()

$ egrep --before-context=10 "\} // cwrap_log_stats" cwrap.out
#79580 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Debug_cc()
#79581 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_DebugLogger_cc()
#79582 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_DebugCmds_cc()
#79583 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Data_cc()
#79584 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_DTLS_cc()
#79585 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Config_cc()
#79586 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_BroString_cc()
#79587 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Base64_cc()
#79588 T13115 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Ascii_cc()
#79589 T13115 C0   - 53,759 calls to 1,441 of 109,535 functions instrumented
#79590 T13115 C0   } // cwrap_log_stats()
```
Eventually, after all the static initialization, then function `main()` is called:
```
$ egrep --after-context=10 "\+ main" cwrap.out
#66927 T13115 C0 + main() { // #1
#66928 T13115 C0   + std::__cxx11::basic_string<>::basic_string<>() { // #323
#66929 T13115 C0     + std::char_traits<>::length() { // #323
#66930 T13115 C0       + std::__constant_string_p<>() {} // #323
#66931 T13115 C0       } // std::char_traits<>::length()
#66932 T13115 C0     + std::__cxx11::basic_string<>::_M_construct<>() { // #323
#66933 T13115 C0       + std::__cxx11::basic_string<>::_M_construct_aux<>() { // #323
#66934 T13115 C0         + std::__cxx11::basic_string<>::_M_construct<>() { // #326
#66935 T13115 C0           + __gnu_cxx::__is_null_pointer<>() {} // #326
#66936 T13115 C0           + std::iterator_traits<>::std::distance<>() { // #326
#66937 T13115 C0             + std::iterator_traits<>::std::__iterator_category<>() {} // #326
```
Examining calls to a particular function:
```
$ cat cwrap.out | egrep "zeekenv"
#67632 T13115 C0       + zeekenv() { // #1
#67710 T13115 C0         } // zeekenv()
#67713 T13115 C0       + zeekenv() { // #2
#67781 T13115 C0         } // zeekenv()
#67784 T13115 C0       + zeekenv() { // #3
#67852 T13115 C0         } // zeekenv()
#67867 T13115 C0       + zeekenv() { // #4
#67955 T13115 C0         } // zeekenv()
#67958 T13115 C0       + zeekenv() { // #5
#68026 T13115 C0         } // zeekenv()
#68044 T13115 C0     + zeekenv() { // #6
#68132 T13115 C0       } // zeekenv()
#68133 T13115 C0     + zeekenv() { // #7
#68197 T13115 C0       } // zeekenv()
#79368 T13115 C0   - 7 calls to 1 of 1 function variation for zeekenv()
```

Running cwrap auto instrumented `zeek hello.zeek`
-----------
Set up the environment for freshly built Zeek, create `hello.zeek` script file, and run without cwrap verbosity enabled:
```
$ cd build/ ; chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh

$ cat << EOF > hello.zeek
# File "hello.zeek"

event zeek_init()
    {
    print "Hello World!";
    }
EOF

$ time zeek hello.zeek
Hello World!
real    0m0.777s

$ time zeek --tracefile trace-zeek.txt hello.zeek
Execution tracing ON.
Hello World!
real    0m0.786s

$ cat trace-zeek.txt | wc -l
25,789

$ time zeek --bare-mode hello.zeek
Hello World!
real    0m0.351s
```
Run with cwrap verbosity enabled:
```
$ CWRAP_LOG_STATS=1 CWRAP_LOG_NUM=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_FILE=1 CWRAP_LOG_CURT=1 CWRAP_LOG_VERBOSITY_SET=1 time zeek hello.zeek
Hello World!
16.47user 23.62system 0:39.56elapsed 101%CPU (0avgtext+0avgdata 177268maxresident)k

$ wc -l cwrap.out
18,702,891 cwrap.out

$ wc --bytes cwrap.out
3,313,123,425 cwrap.out

$ egrep --before-context=10 "\} // cwrap_log_stats" cwrap.out
#18702718 T14389 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Config_cc()
#18702719 T14389 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_BroString_cc()
#18702720 T14389 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Base64_cc()
#18702721 T14389 C0   - 1 calls to 1 of 1 function variation for _GLOBAL__sub_I_Ascii_cc()
#18702722 T14389 C0   - 14 calls to 1 of 1 function variation for Ref_Prefix()
#18702723 T14389 C0   - 16 calls to 1 of 1 function variation for New_Patricia()
#18702724 T14389 C0   - 7 calls to 1 of 1 function variation for Destroy_Patricia()
#18702725 T14389 C0   - 28 calls to 1 of 1 function variation for Deref_Prefix()
#18702726 T14389 C0   - 7 calls to 1 of 1 function variation for Clear_Patricia()
#18702727 T14389 C0   - 62,513,208 calls to 19,962 of 109,535 functions instrumented
#18702728 T14389 C0   } // cwrap_log_stats()
```
Which function calls are called the most excluding `std::` and `__gnu_cxx::` function names?
```
$ cat cwrap.out | egrep "calls to .* function variation" | perl -lane 'm~([\d\,]+) calls to ~; $c=$1; $c=~s~,~~g; push @calls, sprintf qq[%012d %s\n], $c, $_; sub END{ foreach(sort @calls){ s~^\d+ ~~; printf qq[%s],$_; } }' | egrep -v "(std::|__gnu_cxx::)" | tail
#18697885 T14389 C0   - 350,266 calls to 1 of 2 function variation for Location::Location()
#18695426 T14389 C0   - 351,588 calls to 1 of 1 function variation for BroType::InternalType()
#18698559 T14389 C0   - 372,020 calls to 2 of 2 function variation for BroObj::~BroObj()
#18702379 T14389 C0   - 444,315 calls to 1 of 2 function variation for streq()
#18698011 T14389 C0   - 448,569 calls to 1 of 1 function variation for BroType::Ref()
#18698560 T14389 C0   - 574,204 calls to 1 of 1 function variation for BroObj::BroObj()
#18702384 T14389 C0   - 642,954 calls to 1 of 1 function variation for Ref()
#18682874 T14389 C0   - 651,371 calls to 1 of 1 function variation for operator new()
#18702380 T14389 C0   - 1,023,646 calls to 1 of 1 function variation for Unref()
#18695424 T14389 C0   - 1,157,043 calls to 1 of 1 function variation for BroType::Tag()
```
How many threads were used?
```
$ cat cwrap.out | perl -lane 'if(m~(T\d+)~){ $h->{$1} ++; } sub END{ foreach(sort keys %{$h}){ printf qq[- thread %s output %d instrumented lines\n], $_, $h->{$_}; } }'
- thread T14389 output 18575270 instrumented lines
- thread T14390 output 33 instrumented lines
- thread T14396 output 97440 instrumented lines
- thread T14397 output 11937 instrumented lines
- thread T14398 output 3110 instrumented lines
- thread T14399 output 4919 instrumented lines
- thread T14400 output 5486 instrumented lines
- thread T14401 output 4695 instrumented lines
```
Example of a new thread starting and ending:
```
$ cat cwrap.out | egrep T14396 | head
#16079367 T14396 C0 + std::thread::_State_impl<>::_M_run() { // #1
#16079372 T14396 C0   + std::thread::_Invoker<>::operator()() { // #1
#16079373 T14396 C0     + std::thread::_Invoker<>::_M_invoke<>() { // #1
#16079374 T14396 C0       + std::remove_reference<>::std::move<>() {} // #1
#16079375 T14396 C0       + std::tuple_element<>::std::get<>() { // #1
#16079376 T14396 C0         + std::tuple_element<>::std::get<>() { // #1
#16079377 T14396 C0           + caf::scheduler::worker<>::start()::std::__get_helper<>() { // #1
#16079384 T14396 C0             + std::_Tuple_impl<>::_M_head() { // #2
#16079385 T14396 C0               + std::_Head_base<>::_M_head() {} // #2
#16079386 T14396 C0               } // std::_Tuple_impl<>::_M_head()
```
```
$ cat cwrap.out | egrep T14396 | tail
#17743733 T14396 C0         + std::__atomic_base<>::operator unsigned long() { // #440
#17743735 T14396 C0           + std::__atomic_base<>::load() { // #519
#17743736 T14396 C0             + std::operator&() {} // #2463
#17743737 T14396 C0             } // std::__atomic_base<>::load()
#17743738 T14396 C0           } // std::__atomic_base<>::operator unsigned long()
#17743739 T14396 C0         } // caf::ref_counted::unique()
#17743740 T14396 C0       + std::__atomic_base<>::fetch_sub() {} // #316
#17743741 T14396 C0       } // caf::ref_counted::deref()
#17743742 T14396 C0     } // caf::intrusive_ptr_release()
#17743743 T14396 C0   } // caf::intrusive_ptr<>::~intrusive_ptr()
```

Notes on cwrap limitations and run-time performance
-----------
Running `zeek hello.zeek` without cwrap verbosity enables takes 0.7 seconds, but with verbosity enabled it takes 16.5 seconds and spews ~ 19 million lines into a 3.3 GB size `cwrap.out` file.

There is a default limit (which can be changed via `CWRAP_LOG_LIMIT=<limit>`) in cwrap which disables function instrumentation output after 10,000 calls. After that, function calls are still counted as if the function verbosity would have caused output. This is a fail safe mechanism to help reduce output size:
```
$ cat cwrap.out | egrep " BroObj::BroObj\(" | tail
#206209 T14389 C0         + BroObj::BroObj() {} // #9992
#206225 T14389 C0         + BroObj::BroObj() {} // #9993
#206241 T14389 C0         + BroObj::BroObj() {} // #9994
#206257 T14389 C0         + BroObj::BroObj() {} // #9995
#206273 T14389 C0         + BroObj::BroObj() {} // #9996
#206289 T14389 C0         + BroObj::BroObj() {} // #9997
#206305 T14389 C0         + BroObj::BroObj() {} // #9998
#206321 T14389 C0         + BroObj::BroObj() {} // #9999
#206337 T14389 C0         + BroObj::BroObj() {} // #10000
#18698560 T14389 C0   - 574,204 calls to 1 of 1 function variation for BroObj::BroObj()
```
Indentation is currently hard-coded to limit at a recursion level of 96, which is 192 spaces on a line of instrumentation output.

Ultimately, Zeek makes 62,513,208 function calls to display "Hello World!" because it first compiles all its builtin scripts before it runs the `hello.zeek` script. And we can ask cwrap to skip over all that compilation using `CWRAP_LOG_QUIET_UNTIL=<function>` and wait until `QueueEventFast()` is called:
```
$ CWRAP_LOG_QUIET_UNTIL=QueueEventFast CWRAP_LOG_STATS=1 CWRAP_LOG_NUM=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_FILE=1 CWRAP_LOG_CURT=1 CWRAP_LOG_VERBOSITY_SET=1 time zeek hello.zeek
Hello World!
4.29user 4.19system 0:08.15elapsed 104%CPU (0avgtext+0avgdata 177432maxresident)k

$ wc -l cwrap.out
3,500,841 cwrap.out

$ wc --bytes cwrap.out
296,075,802 cwrap.out

$ egrep --before-context=10 "\} // cwrap_log_stats" cwrap.out
#3500664 T14994 C0   - 4,054 calls to 1 of 1 function variation for delete_vals()
#3500665 T14994 C0   - 701 calls to 1 of 1 function variation for copy_string()
#3500666 T14994 C0   - 1 calls to 1 of 1 function variation for net_finish()
#3500667 T14994 C0   - 1 calls to 1 of 1 function variation for net_delete()
#3500668 T14994 C0   - 731 calls to 1 of 1 function variation for hash_final()
#3500669 T14994 C0   - 73 calls to 1 of 1 function variation for IsIntegral()
#3500670 T14994 C0   - 7 calls to 1 of 1 function variation for Destroy_Patricia()
#3500671 T14994 C0   - 7 calls to 1 of 1 function variation for Deref_Prefix()
#3500672 T14994 C0   - 7 calls to 1 of 1 function variation for Clear_Patricia()
#3500673 T14994 C0   - 5,581,004 calls to 9,911 of 109,535 functions instrumented
#3500674 T14994 C0   } // cwrap_log_stats()

$ head cwrap.out
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1 (<verbosity>[={file|function}-<keyword>][/...]) _QUIET_UNTIL=QueueEventFast _STATS=1 _SHOW=0 _CURT=1 _FILE=1 _NUM=1 _COR_ID=1 _THREAD_ID=1 _STACK_PTR=0 _TIMESTAMP=0 _UNWIND=0 _ON_VALGRIND=0
#1 T14994 C0 + cwrap_log_verbosity_set(verbosity=1) { // #1 [cwrap_log_verbosity_set() ignores verbosity!]
#2 T14994 C0   - verbosity 1 set for 109,535 matches in 109,535 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
#3 T14994 C0   } // cwrap_log_verbosity_set()
#4 T14994 C0 + cwrap_log_quiet_until(name=QueueEventFast) {} // #1 going quiet until function EventMgr::QueueEventFast() [cwrap_log_quiet_until() ignores verbosity!]
#5 T14994 C0 + EventMgr::QueueEventFast() { // #1
#6 T14994 C0   + EventHandlerPtr::EventHandlerPtr() {} // #1
#7 T14994 C0   + std::remove_reference<>::std::move<>() {} // #1
#8 T14994 C0   + List<>::List() {} // #1
#9 T14994 C0   + Event::Event() { // #1
```
To reduce output further we can disable verbosity on large categories of generic functions, e.g. containing `std::` and other function names:
- Here we disable the verbosity of 66,500 more generic functions.
- Execution time is now 1.5 seconds instead of 16.5 seconds.
- Now only 1,733,866 calls are traced at run-time.
- In this way the run-time output flood gates can be adjusted as desired.
```
$ CWRAP_LOG_SHOW=1 zeek | egrep "(std::|__gnu_cxx::|operator|Unref|List<>|::~|table_entry_val_delete_func|Ref|Val::)" | wc -l
66,500

$ CWRAP_LOG_VERBOSITY_SET='1/9=function-std::/9=function-__gnu_cxx/9=function-operator/9=function-Unref/9=function-List<>/9=function-::~/9=function-table_entry_val_delete_func/9=function-Ref/9=function-Val::' CWRAP_LOG_QUIET_UNTIL=QueueEventFast CWRAP_LOG_STATS=1 CWRAP_LOG_NUM=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_FILE=1 CWRAP_LOG_CURT=1 time zeek hello.zeek
Hello World!
1.57user 0.94system 0:02.46elapsed 102%CPU (0avgtext+0avgdata 177696maxresident)k

$ wc -l cwrap.out
880,330 cwrap.out

$ wc --bytes cwrap.out
65,486,218 cwrap.out

$ cat cwrap.out | head
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1/9=function-std::/9=function-__gnu_cxx/9=function-operator/9=function-Unref/9=function-List<>/9=function-::~/9=function-table_entry_val_delete_func/9=function-Ref/9=function-Val:: (<verbosity>[={file|funct
#1 T76051 C0 + cwrap_log_verbosity_set(verbosity=1/9=function-std::/9=function-__gnu_cxx/9=function-operator/9=function-Unref/9=function-List<>/9=function-::~/9=function-table_entry_val_delete_func/9=function-Ref/9=function-Val::) { // #1 [cwrap_log_verbo
#2 T76051 C0   - verbosity 1 set for 109,535 matches in 109,535 functions for 1 byte clause '1' // type=FILE|FUNCTION keyword=(null)
#3 T76051 C0   - verbosity 9 set for 48,062 matches in 109,535 functions for 16 byte clause '9=function-std::' // type=FUNCTION keyword=std::
#4 T76051 C0   - verbosity 9 set for 6,916 matches in 109,535 functions for 20 byte clause '9=function-__gnu_cxx' // type=FUNCTION keyword=__gnu_cxx
#5 T76051 C0   - verbosity 9 set for 10,637 matches in 109,535 functions for 19 byte clause '9=function-operator' // type=FUNCTION keyword=operator
#6 T76051 C0   - verbosity 9 set for 8 matches in 109,535 functions for 16 byte clause '9=function-Unref' // type=FUNCTION keyword=Unref
#7 T76051 C0   - verbosity 9 set for 259 matches in 109,535 functions for 17 byte clause '9=function-List<>' // type=FUNCTION keyword=List<>
#8 T76051 C0   - verbosity 9 set for 9,150 matches in 109,535 functions for 14 byte clause '9=function-::~' // type=FUNCTION keyword=::~
#9 T76051 C0   - verbosity 9 set for 1 matches in 109,535 functions for 38 byte clause '9=function-table_entry_val_delete_func' // type=FUNCTION keyword=table_entry_val_delete_func

$ egrep --before-context=10 "\} // cwrap_log_stats" cwrap.out
#880301 T75797 C0   - 4,054 calls to 1 of 1 function variation(s) for delete_vals()
#880302 T75797 C0   - 701 calls to 1 of 1 function variation(s) for copy_string()
#880303 T75797 C0   - 1 calls to 1 of 1 function variation(s) for net_finish()
#880304 T75797 C0   - 1 calls to 1 of 1 function variation(s) for net_delete()
#880305 T75797 C0   - 731 calls to 1 of 1 function variation(s) for hash_final()
#880306 T75797 C0   - 73 calls to 1 of 1 function variation(s) for IsIntegral()
#880307 T75797 C0   - 7 calls to 1 of 1 function variation(s) for Destroy_Patricia()
#880308 T75797 C0   - 7 calls to 1 of 1 function variation(s) for Deref_Prefix()
#880309 T75797 C0   - 7 calls to 1 of 1 function variation(s) for Clear_Patricia()
#880310 T75797 C0   - 1,733,866 calls to 1,944 of 109,535 functions instrumented
#880311 T75797 C0   } // cwrap_log_stats()

$ cat cwrap.out | egrep "calls to .* function variation" | perl -lane 'm~([\d\,]+) calls to ~; $c=$1; $c=~s~,~~g; push @calls, sprintf qq[%012d %s\n], $c, $_; sub END{ foreach(sort @calls){ s~^\d+ ~~; printf qq[%s],$_; } }' | tail
#878776 T75797 C0   - 14,082 calls to 1 of 1 function variation(s) for ID::Offset()
#878538 T75797 C0   - 14,336 calls to 1 of 1 function variation(s) for Stmt::RegisterAccess()
#878482 T75797 C0   - 16,850 calls to 1 of 1 function variation(s) for HashKey::Size()
#878823 T75797 C0   - 24,591 calls to 1 of 1 function variation(s) for ValManager::GetBool()
#878879 T75797 C0   - 25,372 calls to 1 of 1 function variation(s) for BroString::Reset()
#878998 T75797 C0   - 26,374 calls to 1 of 1 function variation(s) for BroObj::BroObj()
#878884 T75797 C0   - 31,959 calls to 1 of 1 function variation(s) for notifier::Modifiable::Modified()
#880211 T75797 C0   - 60,142 calls to 1 of 2 function variation(s) for RecordType::FieldDecl()
#878488 T75797 C0   - 307,783 calls to 1 of 1 function variation(s) for BroType::InternalType()
#878487 T75797 C0   - 669,268 calls to 1 of 1 function variation(s) for BroType::Tag()
```

Running cwrap auto and manual instrumented `zeek` with pcap
-----------

Grab example pcap file and create a Zeek seed:
```
$ # cd build/ ; chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh

$ wget https://s3.amazonaws.com/tcpreplay-pcap-files/smallFlows.pcap

$ zeek --save-seeds any-non-changing-seed.txt --print-plugins | tail
Zeek::SteppingStone - Stepping stone analyzer (built-in)
Zeek::Syslog - Syslog analyzer UDP-only (built-in)
Zeek::TCP - TCP analyzer (built-in)
Zeek::Teredo - Teredo analyzer (built-in)
Zeek::UDP - UDP Analyzer (built-in)
Zeek::Unified2 - Analyze Unified2 alert files. (built-in)
Zeek::VXLAN - VXLAN analyzer (built-in)
Zeek::X509 - X509 and OCSP analyzer (built-in)
Zeek::XMPP - XMPP analyzer (StartTLS only) (built-in)
Zeek::ZIP - Generic ZIP support analyzer (built-in)

$ wc -l any-non-changing-seed.txt
21 any-non-changing-seed.txt
```

Add manual instrumentation to `internal_md5()` function and recompile Zeek:
```
diff --git a/src/EventHandler.cc b/src/EventHandler.cc
index 9928df9a8..248324b5f 100644
--- a/src/EventHandler.cc
+++ b/src/EventHandler.cc
@@ -1,3 +1,5 @@
+#include "if-no-cwrap.h"
+
 #include "EventHandler.h"
 #include "Event.h"
 #include "Desc.h"
@@ -63,6 +65,7 @@ void EventHandler::SetLocalHandler(Func* f)

 void EventHandler::Call(val_list* vl, bool no_remote)
 	{
+	CWRAP_APPEND("name=%s()", Name());
 #ifdef PROFILE_BRO_FUNCTIONS
 	DEBUG_MSG("Event: %s\n", Name());
 #endif
diff --git a/src/Func.cc b/src/Func.cc
index e13799b5b..9a258823a 100644
--- a/src/Func.cc
+++ b/src/Func.cc
@@ -1,5 +1,7 @@
 // See the file "COPYING" in the main distribution directory for copyright.

+#include "if-no-cwrap.h"
+
 #include "zeek-config.h"
 #include "Func.h"

@@ -306,6 +308,7 @@ int BroFunc::IsPure() const

 Val* BroFunc::Call(val_list* args, Frame* parent) const
 	{
+	CWRAP_APPEND("name=%s()", Name());
 #ifdef PROFILE_BRO_FUNCTIONS
 	DEBUG_MSG("Function: %s\n", Name());
 #endif
@@ -628,6 +631,7 @@ int BuiltinFunc::IsPure() const

 Val* BuiltinFunc::Call(val_list* args, Frame* parent) const
 	{
+	CWRAP_APPEND("name=%s()", Name());
 #ifdef PROFILE_BRO_FUNCTIONS
 	DEBUG_MSG("Function: %s\n", Name());
 #endif
diff --git a/src/RuleMatcher.cc b/src/RuleMatcher.cc
index d6cdae8bd..630bbef96 100644
--- a/src/RuleMatcher.cc
+++ b/src/RuleMatcher.cc
@@ -1,3 +1,4 @@
+#include "if-no-cwrap.h"

 #include "zeek-config.h"
 #include "RuleMatcher.h"
@@ -649,6 +650,8 @@ RuleMatcher::MIME_Matches* RuleMatcher::Match(RuleFileMagicState* state,
                                               const u_char* data, uint64_t len,
                                               MIME_Matches* rval) const
 	{
+	CWRAP_PARAMS("data[%'ld]=%s", len, cwrap_log_dump_hex(data, len, 16 /* max chars to dump */));
+	CWRAP_APPEND("matching %s rules", Rule::TypeToString(Rule::FILE_MAGIC));
 	if ( ! rval )
 		rval = new MIME_Matches();

@@ -842,6 +845,8 @@ void RuleMatcher::Match(RuleEndpointState* state, Rule::PatternType type,
 			const u_char* data, int data_len,
 			bool bol, bool eol, bool clear)
 	{
+	CWRAP_PARAMS("data[%'ld]=%s", data_len, cwrap_log_dump_hex(data, data_len, 16 /* max chars to dump */));
+	CWRAP_APPEND("matching %s rules [%d,%d]", Rule::TypeToString(type), bol, eol);
 	if ( ! state )
 		{
 		reporter->Warning("RuleEndpointState not initialized yet.");
diff --git a/src/UID.cc b/src/UID.cc
index 73d61873b..365014774 100644
--- a/src/UID.cc
+++ b/src/UID.cc
@@ -1,5 +1,7 @@
 // See the file "COPYING" in the main distribution directory for copyright.

+#include "if-no-cwrap.h"
+
 #include "UID.h"
 #include "Reporter.h"
 #include "util.h"
@@ -11,6 +13,7 @@ using namespace std;

 void UID::Set(bro_uint_t bits, const uint64_t* v, size_t n)
 	{
+	CWRAP_PARAMS("bits=%d/%d n=%ld", bits, BRO_UID_LEN * 64, n);
 	initialized = true;

 	for ( size_t i = 0; i < BRO_UID_LEN; ++i )
@@ -27,6 +30,8 @@ void UID::Set(bro_uint_t bits, const uint64_t* v, size_t n)

 	if ( res.rem )
 		uid[0] >>= 64 - res.rem;
+
+	CWRAP_APPEND("uid[%'ld bits]=%s", bits, cwrap_log_dump_hex(&uid[0], BRO_UID_LEN * 64 / 8, BRO_UID_LEN * 64 / 8 /* max chars to dump */));
 	}

 std::string UID::Base62(std::string prefix) const
@@ -38,5 +43,6 @@ std::string UID::Base62(std::string prefix) const
 	for ( size_t i = 0; i < BRO_UID_LEN; ++i )
 		prefix.append(uitoa_n(uid[i], tmp, sizeof(tmp), 62));

+	CWRAP_APPEND("prefix=%s=%s", cwrap_log_dump_hex(&uid[0], BRO_UID_LEN * 64 / 8, BRO_UID_LEN * 64 / 8 /* max chars to dump */), prefix.c_str());
 	return prefix;
 	}
diff --git a/src/digest.h b/src/digest.h
index 629ebc0ac..b4fb9960f 100644
--- a/src/digest.h
+++ b/src/digest.h
@@ -6,6 +6,8 @@

 #pragma once

+#include "if-no-cwrap.h"
+
 #include <openssl/md5.h>
 #include <openssl/sha.h>
 #include <openssl/evp.h>
@@ -102,6 +104,7 @@ inline void hash_final(EVP_MD_CTX* c, u_char* md)

 inline unsigned char* internal_md5(const unsigned char* data, unsigned long len, unsigned char* out)
 	{
+	CWRAP_PARAMS("data[%'ld]=%s", len, cwrap_log_dump_hex(data, len, 16 /* max chars to dump */));
 	static unsigned char static_out[MD5_DIGEST_LENGTH];

 	if ( ! out )
@@ -110,5 +113,7 @@ inline unsigned char* internal_md5(const unsigned char* data, unsigned long len,
 	EVP_MD_CTX* c = hash_init(Hash_MD5);
 	hash_update(c, data, len);
 	hash_final(c, out);
+
+	CWRAP_APPEND("out=%s", cwrap_log_dump_hex(&out[0], MD5_DIGEST_LENGTH, MD5_DIGEST_LENGTH /* max chars to dump */));
 	return out;
 	}

$ cp ../../cwrap/if-no-cwrap.h ../src/.
```

Run `zeek` -- and monitor functions `net_run()`, `net_packet_dispatch()`, `internal_md5()`, `BroFunc::Call()`, `BuiltinFunc::Call()`, `RuleMatcher::Match()`, `Bro::UID::Set()`, and `Bro::UID::Base62()` -- while `tcpreplay`ing only 10 packets via `lo`:
```
$ time sudo bash -v -x -s << 'EOF' 2>&1 $(: note: only bash has working jobs -p)
chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh ; which zeek
export ZEEK_RUN_FOLDER=run-zeek ; rm -rf $ZEEK_RUN_FOLDER ; mkdir -p $ZEEK_RUN_FOLDER ; pushd $ZEEK_RUN_FOLDER
CWRAP_LOG_VERBOSITY_SET='1=function-internal_md5/1=function-net_run/1=function-BroFunc::Call/1=function-BuiltinFunc::Call/1=function-RuleMatcher::Match/1=function-UID::Set/1=function-net_packet_dispatch/1=function-UID::Base62' CWRAP_LOG_QUIET_UNTIL=net_run CWRAP_LOG_STATS=1 CWRAP_LOG_NUM=1 CWRAP_LOG_THREAD_ID=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_FILE=1 CWRAP_LOG_CURT=1 zeek --load-seeds ../any-non-changing-seed.txt --iface lo > timestamp-zeek.log 2>&1 &
BASH_PROCESS_GROUP_PIDS=`jobs -p | perl -lane 'push @a, $_; sub END{ printf qq[@a]; }'`
sleep 1
tcpreplay -i lo --pps=100000 --stats=1 --limit 10 --preload-pcap ../smallFlows.pcap
sleep 1
kill -INT $BASH_PROCESS_GROUP_PIDS ; wait $BASH_PROCESS_GROUP_PIDS
find . -type f | egrep timestamp | xargs sort
EOF
```

Zeek generated the following log files:
```
$ find run-zeek/ -type f | egrep "\.log" | egrep -v timestamp | xargs wc -l
  10 run-zeek/packet_filter.log
  10 run-zeek/files.log
  11 run-zeek/conn.log
  10 run-zeek/http.log
  11 run-zeek/reporter.log
```

Show `cwrap.out` and be surprised that only 10 packets causes 683 calls to `internal_md5()`:
```
cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=1=function-internal_md5/1=function-net_run/1=function-BroFunc::Call/1=function-BuiltinFunc::Call/1=function-RuleMatcher::Match/1=function-UID::Set/1=function-net_packet_dispatch/1=function-UID::Base62 (<ver
#1 T34671 C0 0.000078s + cwrap_log_verbosity_set(verbosity=1=function-internal_md5/1=function-net_run/1=function-BroFunc::Call/1=function-BuiltinFunc::Call/1=function-RuleMatcher::Match/1=function-UID::Set/1=function-net_packet_dispatch/1=function-UID::Ba
#2 T34671 C0 0.010346s   - verbosity 1 set for 1 matches in 109,535 functions for 23 byte clause '1=function-internal_md5' // type=FUNCTION keyword=internal_md5
#3 T34671 C0 0.010369s   - verbosity 1 set for 1 matches in 109,535 functions for 18 byte clause '1=function-net_run' // type=FUNCTION keyword=net_run
#4 T34671 C0 0.010372s   - verbosity 1 set for 1 matches in 109,535 functions for 24 byte clause '1=function-BroFunc::Call' // type=FUNCTION keyword=BroFunc::Call
#5 T34671 C0 0.010374s   - verbosity 1 set for 1 matches in 109,535 functions for 28 byte clause '1=function-BuiltinFunc::Call' // type=FUNCTION keyword=BuiltinFunc::Call
#6 T34671 C0 0.010376s   - verbosity 1 set for 2 matches in 109,535 functions for 29 byte clause '1=function-RuleMatcher::Match' // type=FUNCTION keyword=RuleMatcher::Match
#7 T34671 C0 0.010378s   - verbosity 1 set for 1 matches in 109,535 functions for 19 byte clause '1=function-UID::Set' // type=FUNCTION keyword=UID::Set
#8 T34671 C0 0.010380s   - verbosity 1 set for 1 matches in 109,535 functions for 30 byte clause '1=function-net_packet_dispatch' // type=FUNCTION keyword=net_packet_dispatch
#9 T34671 C0 0.010382s   - verbosity 1 set for 1 matches in 109,535 functions for 22 byte clause '1=function-UID::Base62' // type=FUNCTION keyword=UID::Base62
#10 T34671 C0 0.010385s   } // cwrap_log_verbosity_set()
#11 T34671 C0 0.010388s + cwrap_log_quiet_until(name=net_run) {} // #1 going quiet until function net_run() [cwrap_log_quiet_until() ignores verbosity!]
#12 T34671 C0 0.624778s + net_run() { // #1
#13 T34671 C0 0.624996s   + BroFunc::Call() { // #1 name=Broker::log_flush()
#14 T34671 C0 0.625016s     + BroFunc::Call() { // #2 name=Broker::flush_logs()
#15 T34671 C0 0.625021s       + BuiltinFunc::Call() {} // #1 name=Broker::__flush_logs()
#16 T34671 C0 0.625030s       } // BroFunc::Call()
#17 T34671 C0 0.625047s     } // BroFunc::Call()
#18 T34671 C0 0.625056s   + BroFunc::Call() { // #3 name=ChecksumOffloading::check()
#19 T34671 C0 0.625062s     + BuiltinFunc::Call() {} // #2 name=get_net_stats()
#20 T34671 C0 0.625134s     } // BroFunc::Call()
#21 T34671 C0 0.625138s   + BroFunc::Call() {} // #4 name=filter_change_tracking()
#22 T34671 C0 0.625144s   + BroFunc::Call() { // #5 name=net_stats_update()
#23 T34671 C0 0.625147s     + BuiltinFunc::Call() {} // #3 name=get_net_stats()
#24 T34671 C0 0.625176s     } // BroFunc::Call()
#25 T34671 C0 1.005470s   + net_packet_dispatch() { // #1
#26 T34671 C0 1.005905s     + Bro::UID::Set(bits=96/128 n=0) {} // #1 uid[96 bits]=".h......s]....s."=0xf1681e1e-00000000-735da9f6-f5a173a8
#27 T34671 C0 1.005955s     + Bro::UID::Base62() {} // #1 prefix=".h......s]....s."=0xf1681e1e-00000000-735da9f6-f5a173a8=C14ecyXevFmAVbFse
#28 T34671 C0 1.006030s     + RuleMatcher::Match(data[0]=n/a) { // #1 matching Payload rules [1,0]
#29 T34671 C0 1.006054s       + internal_md5(data[7]="43178&."=0x34333137-382600) {} // #1 out="..G.H......}..T."=0x14b947d1-48dae184-17d1947d-b40c54ee
#30 T34671 C0 1.006328s       + internal_md5(data[799]="44178&54178&6617.."=0x34343137-38263534-31373826-36363137..) {} // #2 out="\..p.>X..."!.n.."=0x5c9f1f70-d63e5892-fec32221-c56e03b0
#31 T34671 C0 1.006384s       } // RuleMatcher::Match()
#32 T34671 C0 1.006390s     + RuleMatcher::Match(data[0]=n/a) {} // #2 matching Payload rules [1,0]
#33 T34671 C0 1.006432s     + RuleMatcher::Match(data[943]="GET /complete/se.."=0x47455420-2f636f6d-706c6574-652f7365..) { // #3 matching Payload rules [0,0]
#34 T34671 C0 1.006463s       + internal_md5(data[169]="99578&30678&4367.."=0x39393537-38263330-36373826-34333637..) {} // #3 out="&.t..y.-..VR...H"=0x26ff74f1-e679192d-9b1b5652-99e5e948
#35 T34671 C0 1.006515s       + internal_md5(data[181]="99578&30678&6367.."=0x39393537-38263330-36373826-36333637..) {} // #4 out="t.~..PI.kBxb...."=0x74b27efd-da5049fd-6b427862-c2f7dfce
#36 T34671 C0 1.006556s       + internal_md5(data[175]="99578&30678&8367.."=0x39393537-38263330-36373826-38333637..) {} // #5 out=".t.J[...m.z.W..."=0xb574014a-5b94e193-6dd57a04-57d01e1f
...
#67 T34671 C0 1.007370s       + internal_md5(data[127]="99578&30678&2867.."=0x39393537-38263330-36373826-32383637..) {} // #36 out="..r m.. g..4..MK"=0xf9fb7220-6dbfd120-67c19434-ddd44d4b
#68 T34671 C0 1.007389s       + internal_md5(data[133]="99578&30678&2867.."=0x39393537-38263330-36373826-32383637..) {} // #37 out="...Vb...1b..g?X."=0x99b4e756-622eedff-3162b10a-673f58ea
#69 T34671 C0 1.007407s       + internal_md5(data[133]="99578&30678&2867.."=0x39393537-38263330-36373826-32383637..) {} // #38 out=">.]I.2.D..?C.F.J"=0x3e9c5d49-d832ee44-d7893f43-d546984a
#70 T34671 C0 1.007479s       } // RuleMatcher::Match()
#71 T34671 C0 1.007520s     + BroFunc::Call() {} // #6 name=new_connection()
#72 T34671 C0 1.007580s     } // net_packet_dispatch()
#73 T34671 C0 1.007621s   + net_packet_dispatch() { // #2
#74 T34671 C0 1.007666s     + RuleMatcher::Match(data[0]=n/a) {} // #4 matching Payload rules [1,0]
#75 T34671 C0 1.007677s     + RuleMatcher::Match(data[0]=n/a) {} // #5 matching Payload rules [1,0]
#76 T34671 C0 1.007687s     + RuleMatcher::Match(data[386]="HTTP/1.1 200 OK..."=0x48545450-2f312e31-20323030-204f4b0d..) { // #6 matching Payload rules [0,0]
#77 T34671 C0 1.007724s       + internal_md5(data[181]="99578&30678&3167.."=0x39393537-38263330-36373826-33313637..) {} // #39 out="....1.....@..s]."=0x0c051604-311e83db-009d40f9-be735d82
#78 T34671 C0 1.007760s       + internal_md5(data[181]="99578&30678&6367.."=0x39393537-38263330-36373826-36333637..) {} // #40 out="....g..E.gDg...W"=0xca1c10b7-67f1f945-fb674467-021ba057
#79 T34671 C0 1.007790s       + internal_md5(data[169]="99578&30678&8367.."=0x39393537-38263330-36373826-38333637..) {} // #41 out="......}........."=0x8cb71118-1f9a7d1c-96aced92-a5959583
...
#95 T34671 C0 1.008260s       + internal_md5(data[139]="99578&30678&2867.."=0x39393537-38263330-36373826-32383637..) {} // #57 out="PC.R....-6X....."=0x5043c052-a28602ce-2d365818-041eb21a
#96 T34671 C0 1.008289s       + internal_md5(data[127]="99578&30678&2867.."=0x39393537-38263330-36373826-32383637..) {} // #58 out="..r m.. g..4..MK"=0xf9fb7220-6dbfd120-67c19434-ddd44d4b
#97 T34671 C0 1.008310s       + internal_md5(data[127]="99578&30678&2867.."=0x39393537-38263330-36373826-32383637..) {} // #59 out="..r m.. g..4..MK"=0xf9fb7220-6dbfd120-67c19434-ddd44d4b
#98 T34671 C0 1.008362s       } // RuleMatcher::Match()
#99 T34671 C0 1.008382s     } // net_packet_dispatch()
#100 T34671 C0 1.008403s   + net_packet_dispatch() { // #3
#101 T34671 C0 1.008558s     + Bro::UID::Set(bits=96/128 n=0) {} // #2 uid[96 bits]="KDQ.....#...x..."=0x4b44512e-00000000-23f21414-781c87fb
#102 T34671 C0 1.008579s     + Bro::UID::Base62() {} // #2 prefix="KDQ.....#...x..."=0x4b44512e-00000000-23f21414-781c87fb=CtrxAQj0Clmc7lSAl
#103 T34671 C0 1.008635s     + RuleMatcher::Match(data[0]=n/a) {} // #7 matching Payload rules [1,0]
#104 T34671 C0 1.008643s     + RuleMatcher::Match(data[0]=n/a) {} // #8 matching Payload rules [1,0]
#105 T34671 C0 1.008650s     + BroFunc::Call() {} // #7 name=new_connection()
#106 T34671 C0 1.008672s     } // net_packet_dispatch()
#107 T34671 C0 1.008682s   + net_packet_dispatch() {} // #4
#108 T34671 C0 1.008704s   + net_packet_dispatch() { // #5
#109 T34671 C0 1.008727s     + RuleMatcher::Match(data[0]=n/a) {} // #9 matching Payload rules [1,0]
#110 T34671 C0 1.008744s     + RuleMatcher::Match(data[0]=n/a) {} // #10 matching Payload rules [1,0]
#111 T34671 C0 1.008754s     + BroFunc::Call() {} // #8 name=connection_established()
#112 T34671 C0 1.008786s     } // net_packet_dispatch()
#113 T34671 C0 1.008794s   + net_packet_dispatch() {} // #6
#114 T34671 C0 1.008808s   + net_packet_dispatch() { // #7
#115 T34671 C0 1.008827s     + RuleMatcher::Match(data[45]="/complete/search.."=0x2f636f6d-706c6574-652f7365-61726368..) {} // #11 matching HTTP-REQUEST rules [1,1]
#116 T34671 C0 1.008887s     + RuleMatcher::Match(data[4]="Host"=0x486f7374) {} // #12 matching HTTP-REQUEST-HEADER rules [1,0]
#117 T34671 C0 1.008893s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #13 matching HTTP-REQUEST-HEADER rules [0,0]
#118 T34671 C0 1.008896s     + RuleMatcher::Match(data[18]="clients1.google..."=0x636c6965-6e747331-2e676f6f-676c652e..) {} // #14 matching HTTP-REQUEST-HEADER rules [0,1]
#119 T34671 C0 1.008913s     + RuleMatcher::Match(data[10]="Connection"=0x436f6e6e-65637469-6f6e) {} // #15 matching HTTP-REQUEST-HEADER rules [1,0]
#120 T34671 C0 1.008918s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #16 matching HTTP-REQUEST-HEADER rules [0,0]
#121 T34671 C0 1.008921s     + RuleMatcher::Match(data[10]="keep-alive"=0x6b656570-2d616c69-7665) {} // #17 matching HTTP-REQUEST-HEADER rules [0,1]
#122 T34671 C0 1.008932s     + RuleMatcher::Match(data[10]="User-Agent"=0x55736572-2d416765-6e74) {} // #18 matching HTTP-REQUEST-HEADER rules [1,0]
#123 T34671 C0 1.008936s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #19 matching HTTP-REQUEST-HEADER rules [0,0]
#124 T34671 C0 1.008940s     + RuleMatcher::Match(data[119]="Mozilla/5.0 (Win.."=0x4d6f7a69-6c6c612f-352e3020-2857696e..) {} // #20 matching HTTP-REQUEST-HEADER rules [0,1]
#125 T34671 C0 1.008951s     + RuleMatcher::Match(data[15]="Accept-Encoding"=0x41636365-70742d45-6e636f64-696e67) {} // #21 matching HTTP-REQUEST-HEADER rules [1,0]
#126 T34671 C0 1.008956s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #22 matching HTTP-REQUEST-HEADER rules [0,0]
#127 T34671 C0 1.008959s     + RuleMatcher::Match(data[17]="gzip,deflate,sdc.."=0x677a6970-2c646566-6c617465-2c736463..) {} // #23 matching HTTP-REQUEST-HEADER rules [0,1]
#128 T34671 C0 1.008970s     + RuleMatcher::Match(data[15]="Accept-Language"=0x41636365-70742d4c-616e6775-616765) {} // #24 matching HTTP-REQUEST-HEADER rules [1,0]
#129 T34671 C0 1.008976s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #25 matching HTTP-REQUEST-HEADER rules [0,0]
#130 T34671 C0 1.008979s     + RuleMatcher::Match(data[14]="en-US,en;q=0.8"=0x656e2d55-532c656e-3b713d30-2e38) {} // #26 matching HTTP-REQUEST-HEADER rules [0,1]
#131 T34671 C0 1.009003s     + RuleMatcher::Match(data[14]="Accept-Charset"=0x41636365-70742d43-68617273-6574) {} // #27 matching HTTP-REQUEST-HEADER rules [1,0]
#132 T34671 C0 1.009009s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #28 matching HTTP-REQUEST-HEADER rules [0,0]
#133 T34671 C0 1.009012s     + RuleMatcher::Match(data[30]="ISO-8859-1,utf-8.."=0x49534f2d-38383539-2d312c75-74662d38..) {} // #29 matching HTTP-REQUEST-HEADER rules [0,1]
#134 T34671 C0 1.009023s     + RuleMatcher::Match(data[6]="Cookie"=0x436f6f6b-6965) {} // #30 matching HTTP-REQUEST-HEADER rules [1,0]
#135 T34671 C0 1.009028s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #31 matching HTTP-REQUEST-HEADER rules [0,0]
#136 T34671 C0 1.009031s     + RuleMatcher::Match(data[572]="PREF=ID=c2e35001.."=0x50524546-3d49443d-63326533-35303031..) {} // #32 matching HTTP-REQUEST-HEADER rules [0,1]
#137 T34671 C0 1.009072s     + BroFunc::Call() { // #9 name=protocol_confirmation()
#138 T34671 C0 1.009083s       + BroFunc::Call() { // #10 name=Analyzer::name()
#139 T34671 C0 1.009135s         + BuiltinFunc::Call() {} // #4 name=Analyzer::__name()
#140 T34671 C0 1.009172s         } // BroFunc::Call()
#141 T34671 C0 1.009181s       + BuiltinFunc::Call() {} // #5 name=fmt()
#142 T34671 C0 1.009222s       } // BroFunc::Call()
#143 T34671 C0 1.009234s     + BroFunc::Call() { // #11 name=http_request()
#144 T34671 C0 1.009251s       + BroFunc::Call() { // #12 name=HTTP::set_state()
#145 T34671 C0 1.009272s         + BroFunc::Call() { // #13 name=HTTP::new_http_session()
#146 T34671 C0 1.009300s           + BuiltinFunc::Call() {} // #6 name=network_time()
#147 T34671 C0 1.009313s           } // BroFunc::Call()
#148 T34671 C0 1.009328s         } // BroFunc::Call()
#149 T34671 C0 1.009337s       } // BroFunc::Call()
#150 T34671 C0 1.009341s     + BroFunc::Call() { // #14 name=http_begin_entity()
#151 T34671 C0 1.009345s       + BroFunc::Call() {} // #15 name=HTTP::set_state()
#152 T34671 C0 1.009369s       } // BroFunc::Call()
#153 T34671 C0 1.009373s     + BroFunc::Call() { // #16 name=http_header()
#154 T34671 C0 1.009377s       + BroFunc::Call() {} // #17 name=HTTP::set_state()
#155 T34671 C0 1.009403s       + BuiltinFunc::Call() { // #7 name=split_string1()
#156 T34671 C0 1.009433s         + internal_md5(data[7]="72726&."=0x37323732-362600) {} // #60 out=".R".{.P.3.m.,.;&"=0x135222af-7bb9501c-33b26dad-2cab3b26
#157 T34671 C0 1.009482s         } // BuiltinFunc::Call()
#158 T34671 C0 1.009501s       } // BroFunc::Call()
#159 T34671 C0 1.009505s     + BroFunc::Call() { // #18 name=http_header()
#160 T34671 C0 1.009510s       + BroFunc::Call() {} // #19 name=HTTP::set_state()
#161 T34671 C0 1.009541s       } // BroFunc::Call()
#162 T34671 C0 1.009545s     + BroFunc::Call() { // #20 name=http_header()
#163 T34671 C0 1.009549s       + BroFunc::Call() {} // #21 name=HTTP::set_state()
#164 T34671 C0 1.009567s       } // BroFunc::Call()
#165 T34671 C0 1.009570s     + BroFunc::Call() { // #22 name=http_header()
#166 T34671 C0 1.009573s       + BroFunc::Call() {} // #23 name=HTTP::set_state()
#167 T34671 C0 1.009596s       } // BroFunc::Call()
#168 T34671 C0 1.009599s     + BroFunc::Call() { // #24 name=http_header()
#169 T34671 C0 1.009603s       + BroFunc::Call() {} // #25 name=HTTP::set_state()
#170 T34671 C0 1.009622s       } // BroFunc::Call()
#171 T34671 C0 1.009626s     + BroFunc::Call() { // #26 name=http_header()
#172 T34671 C0 1.009629s       + BroFunc::Call() {} // #27 name=HTTP::set_state()
#173 T34671 C0 1.009649s       } // BroFunc::Call()
#174 T34671 C0 1.009655s     + BroFunc::Call() { // #28 name=http_header()
#175 T34671 C0 1.009658s       + BroFunc::Call() {} // #29 name=HTTP::set_state()
#176 T34671 C0 1.009678s       } // BroFunc::Call()
#177 T34671 C0 1.009682s     + BroFunc::Call() {} // #30 name=http_end_entity()
#178 T34671 C0 1.009690s     + BroFunc::Call() { // #31 name=get_file_handle()
#179 T34671 C0 1.009702s       + BroFunc::Call() { // #32 name=HTTP::get_file_handle()
#180 T34671 C0 1.009719s         + BroFunc::Call() { // #33 name=id_string()
#181 T34671 C0 1.009727s           + BuiltinFunc::Call() {} // #8 name=fmt()
#182 T34671 C0 1.009746s           } // BroFunc::Call()
#183 T34671 C0 1.009749s         + BuiltinFunc::Call() {} // #9 name=cat()
#184 T34671 C0 1.009795s         } // BroFunc::Call()
#185 T34671 C0 1.009798s       + BuiltinFunc::Call() { // #10 name=set_file_handle()
#186 T34671 C0 1.009810s         + internal_md5(data[107]="Analyzer::ANALYZ.."=0x416e616c-797a6572-3a3a414e-414c595a..) {} // #61 out="......3gOC...t[."=0x14b10290-a4913367-4f43f088-88745bb9
#187 T34671 C0 1.009822s         + Bro::UID::Set(bits=96/128 n=2) {} // #3 uid[96 bits]="..3g....OC...t[."=0xa4913367-00000000-4f43f088-88745bb9
#188 T34671 C0 1.009831s         + Bro::UID::Base62() {} // #3 prefix="..3g....OC...t[."=0xa4913367-00000000-4f43f088-88745bb9=FAMUaT17UgrzBlrEUf
#189 T34671 C0 1.009840s         } // BuiltinFunc::Call()
#190 T34671 C0 1.009844s       } // BroFunc::Call()
#191 T34671 C0 1.009904s     + RuleMatcher::Match(data[944]="GET /complete/se.."=0x47455420-2f636f6d-706c6574-652f7365..) {} // #33 matching Payload rules [0,0]
#192 T34671 C0 1.010019s     + BroFunc::Call() { // #34 name=http_message_done()
#193 T34671 C0 1.010029s       + BroFunc::Call() {} // #35 name=HTTP::set_state()
#194 T34671 C0 1.010180s       } // BroFunc::Call()
#195 T34671 C0 1.010211s     } // net_packet_dispatch()
#196 T34671 C0 1.010257s   + net_packet_dispatch() {} // #8
#197 T34671 C0 1.010311s   + net_packet_dispatch() {} // #9
#198 T34671 C0 1.010333s   + net_packet_dispatch() { // #10
#199 T34671 C0 1.010411s     + RuleMatcher::Match(data[4]="Date"=0x44617465) {} // #34 matching HTTP-REPLY-HEADER rules [1,0]
#200 T34671 C0 1.010420s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #35 matching HTTP-REPLY-HEADER rules [0,0]
#201 T34671 C0 1.010423s     + RuleMatcher::Match(data[29]="Tue, 25 Jan 2011.."=0x5475652c-20323520-4a616e20-32303131..) {} // #36 matching HTTP-REPLY-HEADER rules [0,1]
#202 T34671 C0 1.010442s     + RuleMatcher::Match(data[7]="Expires"=0x45787069-726573) {} // #37 matching HTTP-REPLY-HEADER rules [1,0]
#203 T34671 C0 1.010446s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #38 matching HTTP-REPLY-HEADER rules [0,0]
#204 T34671 C0 1.010448s     + RuleMatcher::Match(data[29]="Tue, 25 Jan 2011.."=0x5475652c-20323520-4a616e20-32303131..) {} // #39 matching HTTP-REPLY-HEADER rules [0,1]
#205 T34671 C0 1.010459s     + RuleMatcher::Match(data[13]="Cache-Control"=0x43616368-652d436f-6e74726f-6c) {} // #40 matching HTTP-REPLY-HEADER rules [1,0]
#206 T34671 C0 1.010463s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #41 matching HTTP-REPLY-HEADER rules [0,0]
#207 T34671 C0 1.010466s     + RuleMatcher::Match(data[21]="private, max-age.."=0x70726976-6174652c-206d6178-2d616765..) {} // #42 matching HTTP-REPLY-HEADER rules [0,1]
#208 T34671 C0 1.010477s     + RuleMatcher::Match(data[12]="Content-Type"=0x436f6e74-656e742d-54797065) {} // #43 matching HTTP-REPLY-HEADER rules [1,0]
#209 T34671 C0 1.010482s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #44 matching HTTP-REPLY-HEADER rules [0,0]
#210 T34671 C0 1.010485s     + RuleMatcher::Match(data[30]="text/javascript;.."=0x74657874-2f6a6176-61736372-6970743b..) {} // #45 matching HTTP-REPLY-HEADER rules [0,1]
#211 T34671 C0 1.010498s     + RuleMatcher::Match(data[16]="Content-Encoding"=0x436f6e74-656e742d-456e636f-64696e67) {} // #46 matching HTTP-REPLY-HEADER rules [1,0]
#212 T34671 C0 1.010503s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #47 matching HTTP-REPLY-HEADER rules [0,0]
#213 T34671 C0 1.010506s     + RuleMatcher::Match(data[4]="gzip"=0x677a6970) {} // #48 matching HTTP-REPLY-HEADER rules [0,1]
#214 T34671 C0 1.010515s     + RuleMatcher::Match(data[6]="Server"=0x53657276-6572) {} // #49 matching HTTP-REPLY-HEADER rules [1,0]
#215 T34671 C0 1.010519s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #50 matching HTTP-REPLY-HEADER rules [0,0]
#216 T34671 C0 1.010521s     + RuleMatcher::Match(data[3]="gws"=0x677773) {} // #51 matching HTTP-REPLY-HEADER rules [0,1]
#217 T34671 C0 1.010531s     + RuleMatcher::Match(data[14]="Content-Length"=0x436f6e74-656e742d-4c656e67-7468) {} // #52 matching HTTP-REPLY-HEADER rules [1,0]
#218 T34671 C0 1.010536s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #53 matching HTTP-REPLY-HEADER rules [0,0]
#219 T34671 C0 1.010539s     + RuleMatcher::Match(data[3]="216"=0x323136) {} // #54 matching HTTP-REPLY-HEADER rules [0,1]
#220 T34671 C0 1.010546s     + RuleMatcher::Match(data[16]="X-XSS-Protection"=0x582d5853-532d5072-6f746563-74696f6e) {} // #55 matching HTTP-REPLY-HEADER rules [1,0]
#221 T34671 C0 1.010551s     + RuleMatcher::Match(data[2]=": "=0x3a20) {} // #56 matching HTTP-REPLY-HEADER rules [0,0]
#222 T34671 C0 1.010554s     + RuleMatcher::Match(data[13]="1; mode=block"=0x313b206d-6f64653d-626c6f63-6b) {} // #57 matching HTTP-REPLY-HEADER rules [0,1]
#223 T34671 C0 1.010643s     + BroFunc::Call() { // #36 name=http_reply()
#224 T34671 C0 1.010679s       + BroFunc::Call() {} // #37 name=HTTP::set_state()
#225 T34671 C0 1.010707s       + BroFunc::Call() {} // #38 name=HTTP::code_in_range()
#226 T34671 C0 1.010721s       } // BroFunc::Call()
#227 T34671 C0 1.010724s     + BroFunc::Call() { // #39 name=http_begin_entity()
#228 T34671 C0 1.010728s       + BroFunc::Call() {} // #40 name=HTTP::set_state()
#229 T34671 C0 1.010747s       } // BroFunc::Call()
#230 T34671 C0 1.010761s     + BroFunc::Call() { // #41 name=http_header()
#231 T34671 C0 1.010765s       + BroFunc::Call() {} // #42 name=HTTP::set_state()
#232 T34671 C0 1.010783s       } // BroFunc::Call()
#233 T34671 C0 1.010786s     + BroFunc::Call() { // #43 name=http_header()
#234 T34671 C0 1.010789s       + BroFunc::Call() {} // #44 name=HTTP::set_state()
#235 T34671 C0 1.010807s       } // BroFunc::Call()
#236 T34671 C0 1.010810s     + BroFunc::Call() { // #45 name=http_header()
#237 T34671 C0 1.010812s       + BroFunc::Call() {} // #46 name=HTTP::set_state()
#238 T34671 C0 1.010826s       } // BroFunc::Call()
#239 T34671 C0 1.010829s     + BroFunc::Call() { // #47 name=http_header()
#240 T34671 C0 1.010832s       + BroFunc::Call() {} // #48 name=HTTP::set_state()
#241 T34671 C0 1.010873s       + internal_md5(data[19]="00926&10926&8092.."=0x30303932-36263130-39323626-38303932..) {} // #62 out=",.....Sj:...}k.t"=0x2cbe0adc-84aa536a-3ac383c3-7d6b9974
#242 T34671 C0 1.010917s       + internal_md5(data[19]="00926&10926&8092.."=0x30303932-36263130-39323626-38303932..) {} // #63 out=",.....Sj:...}k.t"=0x2cbe0adc-84aa536a-3ac383c3-7d6b9974
#243 T34671 C0 1.010930s       } // BroFunc::Call()
#244 T34671 C0 1.010934s     + BroFunc::Call() { // #49 name=http_header()
#245 T34671 C0 1.010938s       + BroFunc::Call() {} // #50 name=HTTP::set_state()
#246 T34671 C0 1.010957s       } // BroFunc::Call()
#247 T34671 C0 1.010961s     + BroFunc::Call() { // #51 name=http_header()
#248 T34671 C0 1.010963s       + BroFunc::Call() {} // #52 name=HTTP::set_state()
#249 T34671 C0 1.010979s       } // BroFunc::Call()
#250 T34671 C0 1.010982s     + BroFunc::Call() { // #53 name=http_header()
#251 T34671 C0 1.010984s       + BroFunc::Call() {} // #54 name=HTTP::set_state()
#252 T34671 C0 1.010998s       } // BroFunc::Call()
#253 T34671 C0 1.011001s     + BroFunc::Call() { // #55 name=http_header()
#254 T34671 C0 1.011004s       + BroFunc::Call() {} // #56 name=HTTP::set_state()
#255 T34671 C0 1.011018s       } // BroFunc::Call()
#256 T34671 C0 1.011022s     + BroFunc::Call() { // #57 name=get_file_handle()
#257 T34671 C0 1.011042s       + BroFunc::Call() { // #58 name=HTTP::get_file_handle()
#258 T34671 C0 1.011079s         + BroFunc::Call() { // #59 name=id_string()
#259 T34671 C0 1.011128s           + BuiltinFunc::Call() {} // #11 name=fmt()
#260 T34671 C0 1.011186s           } // BroFunc::Call()
#261 T34671 C0 1.011190s         + BuiltinFunc::Call() {} // #12 name=cat()
#262 T34671 C0 1.011226s         } // BroFunc::Call()
#263 T34671 C0 1.011229s       + BuiltinFunc::Call() { // #13 name=set_file_handle()
#264 T34671 C0 1.011236s         + internal_md5(data[107]="Analyzer::ANALYZ.."=0x416e616c-797a6572-3a3a414e-414c595a..) {} // #64 out="(w+.....>.9....."=0x28772bf9-d8c5829c-3e12399e-faa9c1b0
#265 T34671 C0 1.011247s         + Bro::UID::Set(bits=96/128 n=2) {} // #4 uid[96 bits]="........>.9....."=0xd8c5829c-00000000-3e12399e-faa9c1b0
#266 T34671 C0 1.011254s         + Bro::UID::Base62() {} // #4 prefix="........>.9....."=0xd8c5829c-00000000-3e12399e-faa9c1b0=FmHEHR2SkQwUxYYRaf
#267 T34671 C0 1.011260s         } // BuiltinFunc::Call()
#268 T34671 C0 1.011265s       } // BroFunc::Call()
#269 T34671 C0 1.011384s     + internal_md5(data[48]=".................."=0x00000000-00000000-0000ffff-c0a80383..) {} // #65 out="A..=.7..k..K...^"=0x41fc113d-e537cbca-6bcc944b-c780ee5e
#270 T34671 C0 1.011396s     + internal_md5(data[16]="..........}.. .."=0x08b7d1b1-f4c017a1-19be7d9b-e42001a5) {} // #66 out="_..4.9..:&..R.{+"=0x5fd80234-0239ea91-3a26c3f6-52987b2b
#271 T34671 C0 1.011446s     + BroFunc::Call() { // #60 name=file_new()
#272 T34671 C0 1.011459s       + BroFunc::Call() {} // #61 name=Files::set_info()
#273 T34671 C0 1.011536s       + BroFunc::Call() { // #62 name=Files::enable_reassembly()
#274 T34671 C0 1.011540s         + BuiltinFunc::Call() {} // #14 name=Files::__enable_reassembly()
#275 T34671 C0 1.011551s         } // BroFunc::Call()
#276 T34671 C0 1.011555s       + BroFunc::Call() { // #63 name=Files::set_reassembly_buffer_size()
#277 T34671 C0 1.011559s         + BuiltinFunc::Call() {} // #15 name=Files::__set_reassembly_buffer()
#278 T34671 C0 1.011590s         } // BroFunc::Call()
#279 T34671 C0 1.011597s       } // BroFunc::Call()
#280 T34671 C0 1.011613s     + BroFunc::Call() { // #64 name=file_over_new_connection()
#281 T34671 C0 1.011618s       + BroFunc::Call() {} // #65 name=Files::set_info()
#282 T34671 C0 1.011718s       } // BroFunc::Call()
#283 T34671 C0 1.011746s     + RuleMatcher::Match(data[273]="["msn",["http:\/.."=0x5b226d73-6e222c5b-22687474-703a5c2f..) {} // #58 matching HTTP-REPLY-BODY rules [1,0]
#284 T34671 C0 1.011828s     + RuleMatcher::Match(data[273]="["msn",["http:\/.."=0x5b226d73-6e222c5b-22687474-703a5c2f..) { // #1 matching File Magic rules
#285 T34671 C0 1.011909s       + internal_md5(data[343]="61946&71946&0394.."=0x36313934-36263731-39343626-30333934..) {} // #67 out="..D/..l."kf....."=0xada1442f-d8956c92-226b66d8-818f82b3
#286 T34671 C0 1.011958s       + internal_md5(data[19]="41656&18656&8475.."=0x34313635-36263138-36353626-38343735..) {} // #68 out="D.7y..n.L.."...@"=0x44db3779-e9d06ebf-4ca58822-18b41d40
#287 T34671 C0 1.011975s       + internal_md5(data[19]="51656&28656&9475.."=0x35313635-36263238-36353626-39343735..) {} // #69 out="...C.......=aR.."=0xe698f343-15fa1e84-d4d6013d-6152ccc1
...
#898 T34671 C0 1.022583s       + internal_md5(data[7]="21968&."=0x32313936-382600) {} // #680 out=">.2ita5..^x....H"=0x3ec13269-7461359d-915e78be-0db3a448
#899 T34671 C0 1.022594s       + internal_md5(data[7]="31078&."=0x33313037-382600) {} // #681 out="....#......6...."=0x1fbf1396-23c61cd1-1719c936-aeecbefc
#900 T34671 C0 1.022605s       + internal_md5(data[7]="41078&."=0x34313037-382600) {} // #682 out="...Sn*.I.89...X."=0x020cd453-6e2aed49-fa38390d-1b8a58eb
#901 T34671 C0 1.022662s       } // RuleMatcher::Match()
#902 T34671 C0 1.022706s     + BroFunc::Call() {} // #66 name=http_end_entity()
#903 T34671 C0 1.022735s     + BroFunc::Call() { // #67 name=file_sniff()
#904 T34671 C0 1.022742s       + BroFunc::Call() {} // #68 name=Files::set_info()
#905 T34671 C0 1.022877s       } // BroFunc::Call()
#906 T34671 C0 1.022959s     + RuleMatcher::Match(data[487]="HTTP/1.1 200 OK..."=0x48545450-2f312e31-20323030-204f4b0d..) {} // #59 matching Payload rules [0,0]
#907 T34671 C0 1.023020s     + BroFunc::Call() { // #69 name=file_state_remove()
#908 T34671 C0 1.023026s       + BroFunc::Call() {} // #70 name=Files::set_info()
#909 T34671 C0 1.023077s       + BroFunc::Call() { // #71 name=Log::write()
#910 T34671 C0 1.023085s         + BuiltinFunc::Call() {} // #16 name=Log::__write()
#911 T34671 C0 1.023644s         } // BroFunc::Call()
#912 T34671 C0 1.023658s       } // BroFunc::Call()
#913 T34671 C0 1.023662s     + BroFunc::Call() { // #72 name=http_message_done()
#914 T34671 C0 1.023667s       + BroFunc::Call() {} // #73 name=HTTP::set_state()
#915 T34671 C0 1.023696s       + BroFunc::Call() {} // #74 name=HTTP::code_in_range()
#916 T34671 C0 1.023703s       + BroFunc::Call() { // #75 name=Log::write()
#917 T34671 C0 1.023705s         + BuiltinFunc::Call() {} // #17 name=Log::__write()
#918 T34671 C0 1.024162s         } // BroFunc::Call()
#919 T34671 C0 1.024178s       } // BroFunc::Call()
#920 T34671 C0 1.024183s     } // net_packet_dispatch()
#921 T34671 C0 1.626416s   + BroFunc::Call() { // #76 name=Broker::log_flush()
#922 T34671 C0 1.626508s     + BroFunc::Call() { // #77 name=Broker::flush_logs()
#923 T34671 C0 1.626572s       + BuiltinFunc::Call() {} // #18 name=Broker::__flush_logs()
#924 T34671 C0 1.626629s       } // BroFunc::Call()
#925 T34671 C0 1.626654s     } // BroFunc::Call()
#926 T34671 C0 2.031062s   + BroFunc::Call() { // #78 name=reporter_info()
#927 T34671 C0 2.031108s     + BroFunc::Call() { // #79 name=Log::write()
#928 T34671 C0 2.031117s       + BuiltinFunc::Call() {} // #19 name=Log::__write()
#929 T34671 C0 2.031752s       } // BroFunc::Call()
#930 T34671 C0 2.031760s     } // BroFunc::Call()
#931 T34671 C0 2.031766s   + BroFunc::Call() { // #80 name=reporter_info()
#932 T34671 C0 2.031775s     + BroFunc::Call() { // #81 name=Log::write()
#933 T34671 C0 2.031779s       + BuiltinFunc::Call() {} // #20 name=Log::__write()
#934 T34671 C0 2.031807s       } // BroFunc::Call()
#935 T34671 C0 2.031811s     } // BroFunc::Call()
#936 T34671 C0 2.031818s   + BroFunc::Call() {} // #82 name=net_done()
#937 T34671 C0 2.031898s   + BroFunc::Call() { // #83 name=Broker::log_flush()
#938 T34671 C0 2.031902s     + BroFunc::Call() { // #84 name=Broker::flush_logs()
#939 T34671 C0 2.031914s       + BuiltinFunc::Call() {} // #21 name=Broker::__flush_logs()
#940 T34671 C0 2.031924s       } // BroFunc::Call()
#941 T34671 C0 2.031927s     } // BroFunc::Call()
#942 T34671 C0 2.031929s   + BroFunc::Call() { // #85 name=ChecksumOffloading::check()
#943 T34671 C0 2.031936s     + BuiltinFunc::Call() {} // #22 name=get_net_stats()
#944 T34671 C0 2.032034s     } // BroFunc::Call()
#945 T34671 C0 2.032038s   + BroFunc::Call() { // #86 name=net_stats_update()
#946 T34671 C0 2.032043s     + BuiltinFunc::Call() {} // #23 name=get_net_stats()
#947 T34671 C0 2.032074s     } // BroFunc::Call()
#948 T34671 C0 2.032077s   + BroFunc::Call() {} // #87 name=filter_change_tracking()
#949 T34671 C0 2.032172s   + BroFunc::Call() { // #88 name=get_file_handle()
#950 T34671 C0 2.032197s     + BroFunc::Call() { // #89 name=HTTP::get_file_handle()
#951 T34671 C0 2.032218s       + BroFunc::Call() { // #90 name=id_string()
#952 T34671 C0 2.032227s         + BuiltinFunc::Call() {} // #24 name=fmt()
#953 T34671 C0 2.032249s         } // BroFunc::Call()
#954 T34671 C0 2.032251s       + BuiltinFunc::Call() {} // #25 name=cat()
#955 T34671 C0 2.032277s       } // BroFunc::Call()
#956 T34671 C0 2.032280s     + BuiltinFunc::Call() { // #26 name=set_file_handle()
#957 T34671 C0 2.032285s       + internal_md5(data[107]="Analyzer::ANALYZ.."=0x416e616c-797a6572-3a3a414e-414c595a..) {} // #683 out="......3gOC...t[."=0x14b10290-a4913367-4f43f088-88745bb9
#958 T34671 C0 2.032303s       + Bro::UID::Set(bits=96/128 n=2) {} // #5 uid[96 bits]="..3g....OC...t[."=0xa4913367-00000000-4f43f088-88745bb9
#959 T34671 C0 2.032308s       + Bro::UID::Base62() {} // #5 prefix="..3g....OC...t[."=0xa4913367-00000000-4f43f088-88745bb9=FAMUaT17UgrzBlrEUf
#960 T34671 C0 2.032314s       } // BuiltinFunc::Call()
#961 T34671 C0 2.032316s     } // BroFunc::Call()
#962 T34671 C0 2.032324s   + RuleMatcher::Match(data[0]=n/a) {} // #60 matching Payload rules [0,1]
#963 T34671 C0 2.032373s   + RuleMatcher::Match(data[0]=n/a) {} // #61 matching Payload rules [0,1]
#964 T34671 C0 2.032426s   + BroFunc::Call() { // #91 name=connection_state_remove()
#965 T34671 C0 2.032432s     + BroFunc::Call() { // #92 name=Conn::set_conn()
#966 T34671 C0 2.032479s       + BuiltinFunc::Call() {} // #27 name=get_port_transport_proto()
#967 T34671 C0 2.032530s       + BroFunc::Call() { // #93 name=Conn::determine_service()
#968 T34671 C0 2.032548s         + BuiltinFunc::Call() {} // #28 name=sub_bytes()
#969 T34671 C0 2.032560s         + BuiltinFunc::Call() {} // #29 name=to_lower()
#970 T34671 C0 2.032566s         } // BroFunc::Call()
#971 T34671 C0 2.032584s       + BuiltinFunc::Call() {} // #30 name=get_port_transport_proto()
#972 T34671 C0 2.032589s       + BroFunc::Call() {} // #94 name=Conn::conn_state()
#973 T34671 C0 2.032609s       } // BroFunc::Call()
#974 T34671 C0 2.032614s     + BuiltinFunc::Call() {} // #31 name=reading_traces()
#975 T34671 C0 2.032620s     } // BroFunc::Call()
#976 T34671 C0 2.032623s   + BroFunc::Call() { // #95 name=successful_connection_remove()
#977 T34671 C0 2.032661s     + BroFunc::Call() {} // #96 name=KRB::fill_in_subjects()
#978 T34671 C0 2.032691s     + BroFunc::Call() {} // #97 name=KRB::do_log()
#979 T34671 C0 2.032727s     + BroFunc::Call() { // #98 name=Log::write()
#980 T34671 C0 2.032729s       + BuiltinFunc::Call() {} // #32 name=Log::__write()
#981 T34671 C0 2.033176s       } // BroFunc::Call()
#982 T34671 C0 2.033186s     } // BroFunc::Call()
#983 T34671 C0 2.033190s   + BroFunc::Call() { // #99 name=get_file_handle()
#984 T34671 C0 2.033200s     + BroFunc::Call() {} // #100 name=HTTP::get_file_handle()
#985 T34671 C0 2.033207s     + BuiltinFunc::Call() {} // #33 name=set_file_handle()
#986 T34671 C0 2.033211s     } // BroFunc::Call()
#987 T34671 C0 2.033218s   + RuleMatcher::Match(data[0]=n/a) {} // #62 matching Payload rules [0,1]
#988 T34671 C0 2.033225s   + RuleMatcher::Match(data[0]=n/a) {} // #63 matching Payload rules [0,1]
#989 T34671 C0 2.033244s   + BroFunc::Call() { // #101 name=connection_state_remove()
#990 T34671 C0 2.033248s     + BroFunc::Call() { // #102 name=Conn::set_conn()
#991 T34671 C0 2.033260s       + BuiltinFunc::Call() {} // #34 name=get_port_transport_proto()
#992 T34671 C0 2.033273s       + BroFunc::Call() { // #103 name=Conn::determine_service()
#993 T34671 C0 2.033276s         + BuiltinFunc::Call() {} // #35 name=to_lower()
#994 T34671 C0 2.033282s         } // BroFunc::Call()
#995 T34671 C0 2.033286s       + BuiltinFunc::Call() {} // #36 name=get_port_transport_proto()
#996 T34671 C0 2.033289s       + BroFunc::Call() {} // #104 name=Conn::conn_state()
#997 T34671 C0 2.033302s       } // BroFunc::Call()
#998 T34671 C0 2.033305s     + BuiltinFunc::Call() {} // #37 name=reading_traces()
#999 T34671 C0 2.033309s     } // BroFunc::Call()
#1000 T34671 C0 2.033311s   + BroFunc::Call() { // #105 name=successful_connection_remove()
#1001 T34671 C0 2.033323s     + BroFunc::Call() {} // #106 name=KRB::fill_in_subjects()
#1002 T34671 C0 2.033337s     + BroFunc::Call() {} // #107 name=KRB::do_log()
#1003 T34671 C0 2.033364s     + BroFunc::Call() { // #108 name=Log::write()
#1004 T34671 C0 2.033366s       + BuiltinFunc::Call() {} // #38 name=Log::__write()
#1005 T34671 C0 2.033407s       } // BroFunc::Call()
#1006 T34671 C0 2.033414s     } // BroFunc::Call()
#1007 T34671 C0 2.033548s   + BroFunc::Call() {} // #109 name=zeek_done()
#1008 T34671 C0 2.033580s   + BroFunc::Call() { // #110 name=ChecksumOffloading::check()
#1009 T34671 C0 2.033583s     + BuiltinFunc::Call() {} // #39 name=get_net_stats()
#1010 T34671 C0 2.033634s     } // BroFunc::Call()
#1011 T34671 C0 2.153137s + cwrap_log_stats() { // #1 [cwrap_log_stats() ignores verbosity!]
#1012 T34671 C0 2.153151s   - 1 calls to 1 of 1 function variation(s) for cwrap_log_stats()
#1013 T34671 C0 2.153171s   - 1 calls to 1 of 1 function variation(s) for cwrap_log_verbosity_set()
#1014 T34671 C0 2.153173s   - 1 calls to 1 of 1 function variation(s) for cwrap_log_quiet_until()
#1015 T34671 C0 2.153774s   - 110 calls to 1 of 1 function variation(s) for BroFunc::Call()
#1016 T34671 C0 2.153884s   - 5 calls to 1 of 1 function variation(s) for Bro::UID::Base62()
#1017 T34671 C0 2.153891s   - 1 calls to 2 of 2 function variation(s) for RuleMatcher::Match()
#1018 T34671 C0 2.153894s   - 39 calls to 1 of 1 function variation(s) for BuiltinFunc::Call()
#1019 T34671 C0 2.154438s   - 5 calls to 1 of 1 function variation(s) for Bro::UID::Set()
#1020 T34671 C0 2.154455s   - 63 calls to 1 of 2 function variation(s) for RuleMatcher::Match()
#1021 T34671 C0 2.154471s   - 1 calls to 1 of 1 function variation(s) for net_run()
#1022 T34671 C0 2.154482s   - 10 calls to 1 of 1 function variation(s) for net_packet_dispatch()
#1023 T34671 C0 2.154486s   - 683 calls to 1 of 1 function variation(s) for internal_md5()
#1024 T34671 C0 2.154491s   } // cwrap_log_stats()
```

Most of the 683 calls to `internal_md5()` happen on packet 10 due to lazy regex deterministic finite automation.

Zeek performance: Production vs cwrap production vs debug vs cwrap debug
-----------

Prerequisites for each for the four zeek builds:
```
$ git clone https://github.com/corelight/cwrap.git
$ pushd cwrap/test/ ; perl cwrap-test.pl ; popd

$ wget https://s3.amazonaws.com/tcpreplay-pcap-files/bigFlows.pcap # example larger pcap

$ sudo apt-get install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev ninja-build # install prerequisites
```

Build and run production zeek:
```
$ mkdir zeek ; cd zeek
$ git clone --recursive --branch v3.1.2 --single-branch https://github.com/zeek/zeek.git
$ cd zeek/
$ make distclean && ./configure
$ time make -j`nproc` 2>&1 | egrep --line-buffered -v "(Entering|Leaving)" | tee ./build/make-j`nproc`.log
...
[100%] Built target zeek
real    6m57.746s
$ cd build/
$ wc --bytes src/zeek
265,246,040 build/src/zeek
$ chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh ; which zeek ; zeek --save-seeds ../../../any-non-changing-seed.txt --print-plugins | tail
/home/simon/20200507-zeek-cwrap-perf/zeek/zeek/build/src/zeek
Zeek::SteppingStone - Stepping stone analyzer (built-in)
Zeek::Syslog - Syslog analyzer UDP-only (built-in)
Zeek::TCP - TCP analyzer (built-in)
Zeek::Teredo - Teredo analyzer (built-in)
Zeek::UDP - UDP Analyzer (built-in)
Zeek::Unified2 - Analyze Unified2 alert files. (built-in)
Zeek::VXLAN - VXLAN analyzer (built-in)
Zeek::X509 - X509 and OCSP analyzer (built-in)
Zeek::XMPP - XMPP analyzer (StartTLS only) (built-in)
Zeek::ZIP - Generic ZIP support analyzer (built-in)
$ time sudo bash -v -x -s << 'EOF' 2>&1 $(: note: only bash has working jobs -p)
chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh ; which zeek
export ZEEK_RUN_FOLDER=run-zeek ; rm -rf $ZEEK_RUN_FOLDER ; mkdir -p $ZEEK_RUN_FOLDER ; pushd $ZEEK_RUN_FOLDER
zeek --load-seeds ../../../../any-non-changing-seed.txt --iface lo > timestamp-zeek.log 2>&1 &
BASH_PROCESS_GROUP_PIDS=`jobs -p | perl -lane 'push @a, $_; sub END{ printf qq[@a]; }'`
sleep 1
tcpreplay -i lo --pps=30000 --stats=1 --preload-pcap ../../../../bigFlows.pcap
sleep 1
kill -INT $BASH_PROCESS_GROUP_PIDS ; wait $BASH_PROCESS_GROUP_PIDS
find . -type f | egrep timestamp | xargs sort
EOF
...
1588896072.070733 791615 packets received on interface lo, 0 (0.00%) dropped
1588896072.070733 received termination signal
real    0m31.213s
user    0m18.009s
sys     0m23.954s
```

Build and run production zeek with cwrap:
```
$ mkdir zeek-cwrap ; cd zeek-cwrap
$ git clone --recursive --branch v3.1.2 --single-branch https://github.com/zeek/zeek.git
$ cd zeek/
$ make distclean && CC=`pwd`/../../cwrap/cwrap.pl CXX=$CC ./configure
$ time make -j`nproc` 2>&1 | egrep --line-buffered -v "(Entering|Leaving)" | tee ./build/make-j`nproc`.log

$ # note: currently fails due to in-lined assembler generated by gcc being too complex for cwrap to figure out.
```

Build and run debug zeek:
```
$ mkdir zeek-debug ; cd zeek-debug
$ git clone --recursive --branch v3.1.2 --single-branch https://github.com/zeek/zeek.git
$ cd zeek/
$ make distclean && ./configure --build-type=Debug --enable-debug
$ time make -j`nproc` 2>&1 | egrep --line-buffered -v "(Entering|Leaving)" | tee ./build/make-j`nproc`.log
...
[100%] Built target zeek
real    5m23.070s
$ cd build/
$ wc --bytes src/zeek
213,651,456 build/src/zeek
$ time sudo bash -v -x -s << 'EOF' 2>&1 $(: note: only bash has working jobs -p)
chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh ; which zeek
export ZEEK_RUN_FOLDER=run-zeek ; rm -rf $ZEEK_RUN_FOLDER ; mkdir -p $ZEEK_RUN_FOLDER ; pushd $ZEEK_RUN_FOLDER
zeek --load-seeds ../../../../any-non-changing-seed.txt --iface lo > timestamp-zeek.log 2>&1 &
BASH_PROCESS_GROUP_PIDS=`jobs -p | perl -lane 'push @a, $_; sub END{ printf qq[@a]; }'`
sleep 1
tcpreplay -i lo --pps=30000 --stats=1 --preload-pcap ../../../../bigFlows.pcap
sleep 1
kill -INT $BASH_PROCESS_GROUP_PIDS ; wait $BASH_PROCESS_GROUP_PIDS
find . -type f | egrep timestamp | xargs sort
EOF
...
1588896010.236877 791627 packets received on interface lo, 0 (0.00%) dropped
1588896010.236877 received termination signal
real    0m31.758s
user    0m29.873s
sys     0m23.835s
```

Build and run debug zeek with cwrap:
```
$ mkdir zeek-debug-cwrap ; cd zeek-debug-cwrap
$ git clone --recursive --branch v3.1.2 --single-branch https://github.com/zeek/zeek.git
$ cd zeek/
$ make distclean && CC=`pwd`/../../cwrap/cwrap.pl CXX=$CC ./configure --build-type=Debug --enable-debug
$ time make -j`nproc` 2>&1 | egrep --line-buffered -v "(Entering|Leaving)" | tee ./build/make-j`nproc`.log
...
[100%] Built target zeek
real    7m37.442s
$ cd build/
$ wc --bytes src/zeek
278,500,040 build/src/zeek
$ time sudo bash -v -x -s << 'EOF' 2>&1 $(: note: only bash has working jobs -p)
chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh ; which zeek
export ZEEK_RUN_FOLDER=run-zeek ; rm -rf $ZEEK_RUN_FOLDER ; mkdir -p $ZEEK_RUN_FOLDER ; pushd $ZEEK_RUN_FOLDER
zeek --load-seeds ../../../../any-non-changing-seed.txt --iface lo > timestamp-zeek.log 2>&1 &
BASH_PROCESS_GROUP_PIDS=`jobs -p | perl -lane 'push @a, $_; sub END{ printf qq[@a]; }'`
sleep 1
tcpreplay -i lo --pps=30000 --stats=1 --preload-pcap ../../../../bigFlows.pcap
sleep 1
kill -INT $BASH_PROCESS_GROUP_PIDS ; wait $BASH_PROCESS_GROUP_PIDS
find . -type f | egrep timestamp | xargs sort
EOF
...
1588895943.535181 791649 packets received on interface lo, 0 (0.00%) dropped
1588895943.535181 received termination signal
real    0m30.837s
user    0m36.867s
sys     0m23.464s
```

Note: Giving `tcpreplay` a PPS bigger than 30,000 resulted in dropped packets on my box.

Zeek binary sizes for each compile:
```
265,246,040 build/src/zeek <-- production
213,651,456 build/src/zeek <-- debug
278,500,040 build/src/zeek <-- debug with cwrap
```

Note: The production Zeek is much bigger than the debug Zeek. Why? This might be because of excessive amounts of gcc function in-lining which bloats the binary with effectively many copies of the frequently used functions.

Zeek user time for each tcpreplay:
```
user    0m18.009s <-- production
user    0m29.873s <-- debug
user    0m36.867s <-- debug with cwrap
```

This shows that cwrap introduces a significant performance overhead of about 20% even if all instrumentation is disabled at run-time.

Further investigation needs to be done to determine if most of this performance overhead is due to smaller, generally uninteresting for analysis, but very frequently called functions. In which case, a new feature for cwrap could be to avoid instrumenting those functions.

It would be interesting to performance production Zeek with different types of gcc compile options, e.g. optimize for size versus optimize for speed (which it is currently). It would also be interesting to test this out on an object file by object file basis.

Run cwrap debug Zeek which logging `net_packet_dispatch()` without cwrap curt output in order to see how long processing of each packet takes:
```
$ time sudo bash -v -x -s << 'EOF' 2>&1 $(: note: only bash has working jobs -p)
chmod +x zeek-path-dev.sh ; source ./zeek-path-dev.sh ; which zeek
export ZEEK_RUN_FOLDER=run-zeek ; rm -rf $ZEEK_RUN_FOLDER ; mkdir -p $ZEEK_RUN_FOLDER ; pushd $ZEEK_RUN_FOLDER
CWRAP_LOG_VERBOSITY_SET='1=function-net_run/1=function-net_packet_dispatch' CWRAP_LOG_QUIET_UNTIL=net_run CWRAP_LOG_STATS=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_FILE=1 CWRAP_LOG_LIMIT=1000000 zeek --load-seeds ../../../../any-non-changing-seed.txt --iface lo > timestamp-zeek.log 2>&1 &
BASH_PROCESS_GROUP_PIDS=`jobs -p | perl -lane 'push @a, $_; sub END{ printf qq[@a]; }'`
sleep 1
tcpreplay -i lo --pps=30000 --stats=1 --preload-pcap ../../../../bigFlows.pcap
sleep 1
kill -INT $BASH_PROCESS_GROUP_PIDS ; wait $BASH_PROCESS_GROUP_PIDS
find . -type f | egrep timestamp | xargs sort
EOF
```

Use a quick Perl one-line to see which packets fell into which packet processing time bucket:
```
$ cat run-zeek/cwrap.out | perl -lane 'if(0){printf qq[%s\n],$_;} if(m~C0 ([\d+\.]+)s .*(.) net_packet_dispatch~){ if($2 eq q[+]){ $s=$1 }else{ $e=sprintf qq[%f],$1-$s; if(1){$e=~s~([1-9])\d~$1x~; while($e=~s~x\d~xx~){}} if(0){printf qq[- %s $1 $s\n],$e;} $h->{$e}++; } } sub END{ foreach(sort keys %{$h}){ next if($_ >= 1.0); $sx=$_; $s=$sx; $s=~s~x~5~g; $t=$s * $h->{$_}; printf qq[- %s seconds for packet processing occurred %6u times or %fs total\n], $sx, $h->{$_}, $t; $tt += $t; } printf qq[- %f total seconds for all packet processing\n], $tt; }'
- 0.000002 seconds for packet processing occurred     84 times or 0.000168s total
- 0.000003 seconds for packet processing occurred  25884 times or 0.077652s total
- 0.000004 seconds for packet processing occurred  90277 times or 0.361108s total
- 0.000005 seconds for packet processing occurred  88796 times or 0.443980s total
- 0.000006 seconds for packet processing occurred  87979 times or 0.527874s total
- 0.000007 seconds for packet processing occurred  97311 times or 0.681177s total
- 0.000008 seconds for packet processing occurred  74527 times or 0.596216s total
- 0.000009 seconds for packet processing occurred  29737 times or 0.267633s total
- 0.00001x seconds for packet processing occurred  89601 times or 1.344015s total
- 0.00002x seconds for packet processing occurred  15793 times or 0.394825s total
- 0.00003x seconds for packet processing occurred  12425 times or 0.434875s total
- 0.00004x seconds for packet processing occurred   5964 times or 0.268380s total
- 0.00005x seconds for packet processing occurred  19161 times or 1.053855s total
- 0.00006x seconds for packet processing occurred  13309 times or 0.865085s total
- 0.00007x seconds for packet processing occurred  11021 times or 0.826575s total
- 0.00008x seconds for packet processing occurred  13848 times or 1.177080s total
- 0.00009x seconds for packet processing occurred  11193 times or 1.063335s total
- 0.0001xx seconds for packet processing occurred  21152 times or 3.278560s total
- 0.0002xx seconds for packet processing occurred  10801 times or 2.754255s total
- 0.0003xx seconds for packet processing occurred   4594 times or 1.630870s total
- 0.0004xx seconds for packet processing occurred   2194 times or 0.998270s total
- 0.0005xx seconds for packet processing occurred   1588 times or 0.881340s total
- 0.0006xx seconds for packet processing occurred    458 times or 0.299990s total
- 0.0007xx seconds for packet processing occurred    179 times or 0.135145s total
- 0.0008xx seconds for packet processing occurred    218 times or 0.186390s total
- 0.0009xx seconds for packet processing occurred    201 times or 0.191955s total
- 0.001xxx seconds for packet processing occurred    718 times or 1.116490s total
- 0.002xxx seconds for packet processing occurred     46 times or 0.117530s total
- 0.003xxx seconds for packet processing occurred      5 times or 0.017775s total
- 0.004xxx seconds for packet processing occurred      2 times or 0.009110s total
- 0.005xxx seconds for packet processing occurred      1 times or 0.005555s total
- 0.006xxx seconds for packet processing occurred      1 times or 0.006555s total
- 0.01xxxx seconds for packet processing occurred      1 times or 0.015555s total
- 0.02xxxx seconds for packet processing occurred      1 times or 0.025555s total
- 22.054733 total seconds for all packet processing
```

Note: The 'total' listed on the end is inaccurate because of the 'x's.

This shows that `net_packet_dispatch()` took 0.000003 seconds for 25,884 packets, whereas it took somewhere between 0.020000 and 0.029999 seconds for the slowest to process packet.

It would be interesting to enable more cwrap instrumentation and analyze which areas of processing are the performance hot spots for each packet.

Examining internal C++ trace for a single Zeek script function call
-----------

Create a simple Zeek script which calls function `foo()` in a loop.
```
$ cat hello.zeek
# File "hello.zeek"

function foo(x: count): count {
    return x;
}

event zeek_init()
    {
    print "Hello";
    local x = 0;
    while (x < 10) {
        foo(123);
        ++x;
    }
    print "World!";
    }
```

Run with script with cwrap compiled Zeek:
```
$ CWRAP_LOG_VERBOSITY_SET='1/9=function-std::/9=function-__gnu_cxx/9=function-operator/9=function-Unref/9=function-List<>/9=function-::~/9=function-table_entry_val_delete_func/9=function-Ref/9=function-Val::/9=function-::Name/9=function->' CWRAP_LOG_QUIET_UNTIL=EventMgr::Drain CWRAP_LOG_STATS=1 CWRAP_LOG_NUM=1 CWRAP_LOG_TIMESTAMP=1 CWRAP_LOG_FILE=1 CWRAP_LOG_CURT=0 CWRAP_LOG_LIMIT=1000000 time zeek hello.zeek
Hello
World!
1.91user 1.03system 0:02.86elapsed 102%CPU (0avgtext+0avgdata 178244maxresident)k
```

Have we can see that each call to `foo()` takes about 0.0005 seconds or half a millisecond. Keep in mind that the debug Zeek runs about half the normal speed, and the cwrap compiled debug Zeek runs at least 20% slower than that. The idea is not to get hung up on the actual wallclock times, but to be able to compare the relative function times, e.g. if a C++ function uses 10% of the total time in `foo()` using cwrap instrumented Zeek, it will likely use a similar percentage of time in production compiled Zeek.

Also, note that between each `foo()` call are 289 enter and exit lines suggesting that 289 / 2 = 144 C/C++ functions are called per loop in the above Zeek script. But note, some of the most common `std::` and other, etc, functions have been disabled via verbosity and therefore not counted in the 289.
```
$ cat cwrap.out | egrep "(zeek_init|foo)" | perl -lane 'if(m~\#(\d+) .* ([\d\.]+)s .* name=foo~){ ($n,$s)=($1,$2); if(defined $n_last){ printf qq[%u enter / exits took %f seconds; $_\n], $n - $n_last, $s - $s_last; } $n_last=$n; $s_last=$s; }'
289 enter / exits took 0.000462 seconds; #1791557 C0 3.463344s                     - name=foo()
289 enter / exits took 0.000475 seconds; #1791846 C0 3.463819s                     - name=foo()
289 enter / exits took 0.000459 seconds; #1792135 C0 3.464278s                     - name=foo()
289 enter / exits took 0.000476 seconds; #1792424 C0 3.464754s                     - name=foo()
289 enter / exits took 0.000456 seconds; #1792713 C0 3.465210s                     - name=foo()
289 enter / exits took 0.000471 seconds; #1793002 C0 3.465681s                     - name=foo()
289 enter / exits took 0.000458 seconds; #1793291 C0 3.466139s                     - name=foo()
289 enter / exits took 0.000479 seconds; #1793580 C0 3.466618s                     - name=foo()
289 enter / exits took 0.000458 seconds; #1793869 C0 3.467076s                     - name=foo()
289 enter / exits took 0.000454 seconds; #1794158 C0 3.467530s                     - name=foo()
```

The 144 functions called per Zeek script loop look like this:
```
$ egrep --max-count 1 --before-context=42 --after-context=247 foo cwrap.out
#1791226 C0 3.462814s             + StmtList::Exec() { #4499               // <-- outer 1st foo() call start
#1791227 C0 3.462815s               + Stmt::RegisterAccess() { #14198
#1791228 C0 3.462816s                 } // Stmt::RegisterAccess()
#1791229 C0 3.462819s               + Frame::SetNextStmt() { #9790
#1791230 C0 3.462819s                 } // Frame::SetNextStmt()
#1791231 C0 3.462822s               + pre_execute_stmt() { #9790
#1791232 C0 3.462822s                 } // pre_execute_stmt()
#1791233 C0 3.462825s               + ExprStmt::Exec() { #5101
#1791234 C0 3.462825s                 + Stmt::RegisterAccess() { #14199
#1791235 C0 3.462827s                   } // Stmt::RegisterAccess()
#1791236 C0 3.462830s                 + CallExpr::Eval() { #560
#1791237 C0 3.462830s                   + Expr::IsError() { #10605
#1791238 C0 3.462832s                     + BroType::Tag() { #136043
#1791239 C0 3.462833s                       } // BroType::Tag()
#1791240 C0 3.462836s                     } // Expr::IsError()
#1791241 C0 3.462837s                   + Frame::GetTrigger() { #878
#1791242 C0 3.462838s                     } // Frame::GetTrigger()
#1791243 C0 3.462841s                   + NameExpr::Eval() { #7898
#1791244 C0 3.462841s                     + ID::AsType() { #7943
#1791245 C0 3.462843s                       } // ID::AsType()
#1791246 C0 3.462845s                     + ID::IsGlobal() { #8001
#1791247 C0 3.462846s                       } // ID::IsGlobal()
#1791248 C0 3.462848s                     + ID::ID_Val() { #4922
#1791249 C0 3.462849s                       } // ID::ID_Val()
#1791250 C0 3.462854s                     } // NameExpr::Eval()
#1791251 C0 3.462856s                   + eval_list() { #564
#1791252 C0 3.462857s                     + ListExpr::Exprs() { #564
#1791253 C0 3.462858s                       } // ListExpr::Exprs()
#1791254 C0 3.462861s                     + safe_malloc() { #4722
#1791255 C0 3.462861s                       } // safe_malloc()
#1791256 C0 3.462864s                     + ConstExpr::Eval() { #449
#1791257 C0 3.462864s                       + ConstExpr::Value() { #449
#1791258 C0 3.462866s                         } // ConstExpr::Value()
#1791259 C0 3.462869s                       } // ConstExpr::Eval()
#1791260 C0 3.462870s                     } // eval_list()
#1791261 C0 3.462872s                   + BroType::Tag() { #136044
#1791262 C0 3.462873s                     } // BroType::Tag()
#1791263 C0 3.462875s                   + Frame::GetCall() { #1437
#1791264 C0 3.462876s                     } // Frame::GetCall()
#1791265 C0 3.462878s                   + Frame::SetCall() { #1437
#1791266 C0 3.462879s                     } // Frame::SetCall()
#1791267 C0 3.462881s                   + BroFunc::Call() { #320           // <-- inner 1st foo() call start
#1791268 C0 3.462882s                     - name=foo()
#1791269 C0 3.462885s                     + SegmentProfiler::SegmentProfiler() { #320
#1791270 C0 3.462885s                       } // SegmentProfiler::SegmentProfiler()
#1791271 C0 3.462888s                     + plugin::Manager::HavePluginForHook() { #562
#1791272 C0 3.462889s                       } // plugin::Manager::HavePluginForHook()
#1791273 C0 3.462891s                     + Func::Flavor() { #1032
#1791274 C0 3.462892s                       + Func::FType() { #1802
#1791275 C0 3.462893s                         + BroType::AsFuncType() { #2063
#1791276 C0 3.462895s                           } // BroType::AsFuncType()
#1791277 C0 3.462898s                         } // Func::FType()
#1791278 C0 3.462899s                       + FuncType::Flavor() { #1141
#1791279 C0 3.462900s                         } // FuncType::Flavor()
#1791280 C0 3.462902s                       } // Func::Flavor()
#1791281 C0 3.462904s                     + Func::HandlePluginResult() { #561
#1791282 C0 3.462904s                       } // Func::HandlePluginResult()
#1791283 C0 3.462907s                     + Frame::Frame() { #320
#1791284 C0 3.462908s                       + BroObj::BroObj() { #26321
#1791285 C0 3.462910s                         } // BroObj::BroObj()
#1791286 C0 3.462913s                       } // Frame::Frame()
#1791287 C0 3.462914s                     + Frame::GetTrigger() { #879
#1791288 C0 3.462915s                       } // Frame::GetTrigger()
#1791289 C0 3.462917s                     + Frame::SetTrigger() { #319
#1791290 C0 3.462918s                       + Frame::ClearTrigger() { #319
#1791291 C0 3.462920s                         } // Frame::ClearTrigger()
#1791292 C0 3.462922s                       } // Frame::SetTrigger()
#1791293 C0 3.462924s                     + Frame::GetCall() { #1438
#1791294 C0 3.462924s                       } // Frame::GetCall()
#1791295 C0 3.462927s                     + Frame::SetCall() { #1438
#1791296 C0 3.462927s                       } // Frame::SetCall()
#1791297 C0 3.462930s                     + Frame::GetCall() { #1439
#1791298 C0 3.462931s                       } // Frame::GetCall()
#1791299 C0 3.462934s                     + TraceState::DoTrace() { #1061
#1791300 C0 3.462934s                       } // TraceState::DoTrace()
#1791301 C0 3.462937s                     + Frame::NthElement() { #578
#1791302 C0 3.462938s                       } // Frame::NthElement()
#1791303 C0 3.462940s                     + Frame::SetElement() { #8717
#1791304 C0 3.462940s                       } // Frame::SetElement()
#1791305 C0 3.462943s                     + Frame::Reset() { #396
#1791306 C0 3.462944s                       } // Frame::Reset()
#1791307 C0 3.462946s                     + StmtList::Exec() { #4500
#1791308 C0 3.462947s                       + Stmt::RegisterAccess() { #14200
#1791309 C0 3.462950s                         } // Stmt::RegisterAccess()
#1791310 C0 3.462953s                       + Frame::SetNextStmt() { #9791
#1791311 C0 3.462953s                         } // Frame::SetNextStmt()
#1791312 C0 3.462956s                       + pre_execute_stmt() { #9791
#1791313 C0 3.462956s                         } // pre_execute_stmt()
#1791314 C0 3.462959s                       + ReturnStmt::Exec() { #260
#1791315 C0 3.462960s                         + Stmt::RegisterAccess() { #14201
#1791316 C0 3.462961s                           } // Stmt::RegisterAccess()
#1791317 C0 3.462964s                         + NameExpr::Eval() { #7899
#1791318 C0 3.462965s                           + ID::AsType() { #7944
#1791319 C0 3.462967s                             } // ID::AsType()
#1791320 C0 3.462970s                           + ID::IsGlobal() { #8002
#1791321 C0 3.462970s                             } // ID::IsGlobal()
#1791322 C0 3.462973s                           + Frame::GetElement() { #5880
#1791323 C0 3.462973s                             + ID::Offset() { #14019
#1791324 C0 3.462975s                               } // ID::Offset()
#1791325 C0 3.462977s                             } // Frame::GetElement()
#1791326 C0 3.462979s                           } // NameExpr::Eval()
#1791327 C0 3.462980s                         } // ReturnStmt::Exec()
#1791328 C0 3.462982s                       + post_execute_stmt() { #9789
#1791329 C0 3.462982s                         + Frame::BreakBeforeNextStmt() { #293
#1791330 C0 3.462984s                           } // Frame::BreakBeforeNextStmt()
#1791331 C0 3.462987s                         + Frame::BreakOnReturn() { #293
#1791332 C0 3.462987s                           } // Frame::BreakOnReturn()
#1791333 C0 3.462990s                         } // post_execute_stmt()
#1791334 C0 3.462991s                       } // StmtList::Exec()
#1791335 C0 3.462993s                     + Frame::HasDelayed() { #1624
#1791336 C0 3.462993s                       } // Frame::HasDelayed()
#1791337 C0 3.462996s                     + Func::Flavor() { #1033
#1791338 C0 3.462996s                       + Func::FType() { #1803
#1791339 C0 3.462998s                         + BroType::AsFuncType() { #2064
#1791340 C0 3.463000s                           } // BroType::AsFuncType()
#1791341 C0 3.463002s                         } // Func::FType()
#1791342 C0 3.463004s                       + FuncType::Flavor() { #1142
#1791343 C0 3.463004s                         } // FuncType::Flavor()
#1791344 C0 3.463006s                       } // Func::Flavor()
#1791345 C0 3.463008s                     + Func::Flavor() { #1034
#1791346 C0 3.463009s                       + Func::FType() { #1804
#1791347 C0 3.463010s                         + BroType::AsFuncType() { #2065
#1791348 C0 3.463012s                           } // BroType::AsFuncType()
#1791349 C0 3.463014s                         } // Func::FType()
#1791350 C0 3.463016s                       + FuncType::Flavor() { #1143
#1791351 C0 3.463016s                         } // FuncType::Flavor()
#1791352 C0 3.463019s                       } // Func::Flavor()
#1791353 C0 3.463020s                     + Func::FType() { #1805
#1791354 C0 3.463021s                       + BroType::AsFuncType() { #2066
#1791355 C0 3.463022s                         } // BroType::AsFuncType()
#1791356 C0 3.463025s                       } // Func::FType()
#1791357 C0 3.463027s                     + FuncType::YieldType() { #801
#1791358 C0 3.463027s                       } // FuncType::YieldType()
#1791359 C0 3.463030s                     + Func::FType() { #1806
#1791360 C0 3.463030s                       + BroType::AsFuncType() { #2067
#1791361 C0 3.463032s                         } // BroType::AsFuncType()
#1791362 C0 3.463034s                       } // Func::FType()
#1791363 C0 3.463036s                     + FuncType::YieldType() { #802
#1791364 C0 3.463036s                       } // FuncType::YieldType()
#1791365 C0 3.463041s                     + BroType::Tag() { #136045
#1791366 C0 3.463042s                       } // BroType::Tag()
#1791367 C0 3.463044s                     + TraceState::DoTrace() { #1062
#1791368 C0 3.463045s                       } // TraceState::DoTrace()
#1791369 C0 3.463048s                     + Frame::Release() { #319
#1791370 C0 3.463048s                       } // Frame::Release()
#1791371 C0 3.463052s                     } // BroFunc::Call()             // <-- inner 1st foo() call end
#1791372 C0 3.463054s                   + Frame::SetCall() { #1439
#1791373 C0 3.463054s                     } // Frame::SetCall()
#1791374 C0 3.463057s                   } // CallExpr::Eval()
#1791375 C0 3.463058s                 + ExprStmt::DoExec() { #607
#1791376 C0 3.463059s                   } // ExprStmt::DoExec()
#1791377 C0 3.463061s                 } // ExprStmt::Exec()
#1791378 C0 3.463063s               + post_execute_stmt() { #9790
#1791379 C0 3.463063s                 } // post_execute_stmt()
#1791380 C0 3.463066s               + Frame::HasDelayed() { #1625
#1791381 C0 3.463067s                 } // Frame::HasDelayed()
#1791382 C0 3.463069s               + Frame::SetNextStmt() { #9792
#1791383 C0 3.463069s                 } // Frame::SetNextStmt()
#1791384 C0 3.463072s               + pre_execute_stmt() { #9792
#1791385 C0 3.463072s                 } // pre_execute_stmt()
#1791386 C0 3.463075s               + ExprStmt::Exec() { #5102
#1791387 C0 3.463076s                 + Stmt::RegisterAccess() { #14202
#1791388 C0 3.463077s                   } // Stmt::RegisterAccess()
#1791389 C0 3.463080s                 + IncrExpr::Eval() { #1
#1791390 C0 3.463081s                   + UnaryExpr::Eval() { #9100
#1791391 C0 3.463082s                     + Expr::IsError() { #10606
#1791392 C0 3.463084s                       + BroType::Tag() { #136046
#1791393 C0 3.463085s                         } // BroType::Tag()
#1791394 C0 3.463088s                       } // Expr::IsError()
#1791395 C0 3.463089s                     + NameExpr::Eval() { #7900
#1791396 C0 3.463090s                       + ID::AsType() { #7945
#1791397 C0 3.463092s                         } // ID::AsType()
#1791398 C0 3.463094s                       + ID::IsGlobal() { #8003
#1791399 C0 3.463095s                         } // ID::IsGlobal()
#1791400 C0 3.463097s                       + Frame::GetElement() { #5881
#1791401 C0 3.463097s                         + ID::Offset() { #14020
#1791402 C0 3.463099s                           } // ID::Offset()
#1791403 C0 3.463102s                         } // Frame::GetElement()
#1791404 C0 3.463103s                       } // NameExpr::Eval()
#1791405 C0 3.463105s                     + is_vector() { #9672
#1791406 C0 3.463105s                       + BroType::Tag() { #136047
#1791407 C0 3.463107s                         } // BroType::Tag()
#1791408 C0 3.463109s                       } // is_vector()
#1791409 C0 3.463111s                     + UnaryExpr::Fold() { #189
#1791410 C0 3.463111s                       } // UnaryExpr::Fold()
#1791411 C0 3.463114s                     } // UnaryExpr::Eval()
#1791412 C0 3.463116s                   + is_vector() { #9673
#1791413 C0 3.463116s                     + BroType::Tag() { #136048
#1791414 C0 3.463118s                       } // BroType::Tag()
#1791415 C0 3.463120s                     } // is_vector()
#1791416 C0 3.463122s                   + IncrExpr::DoSingleEval() { #1
#1791417 C0 3.463122s                     + BroType::InternalType() { #39589
#1791418 C0 3.463124s                       } // BroType::InternalType()
#1791419 C0 3.463127s                     + BroType::InternalType() { #39590
#1791420 C0 3.463127s                       } // BroType::InternalType()
#1791421 C0 3.463130s                     + Expr::Tag() { #5
#1791422 C0 3.463130s                       } // Expr::Tag()
#1791423 C0 3.463132s                     + Expr::Type() { #1832
#1791424 C0 3.463133s                       } // Expr::Type()
#1791425 C0 3.463136s                     + BroType::Tag() { #136049
#1791426 C0 3.463136s                       } // BroType::Tag()
#1791427 C0 3.463141s                     + IsVector() { #150
#1791428 C0 3.463141s                       } // IsVector()
#1791429 C0 3.463144s                     + BroType::Tag() { #136050
#1791430 C0 3.463144s                       } // BroType::Tag()
#1791431 C0 3.463146s                     + ValManager::GetCount() { #5
#1791432 C0 3.463147s                       } // ValManager::GetCount()
#1791433 C0 3.463150s                     } // IncrExpr::DoSingleEval()
#1791434 C0 3.463151s                   + NameExpr::Assign() { #144
#1791435 C0 3.463152s                     + ID::IsGlobal() { #8004
#1791436 C0 3.463153s                       } // ID::IsGlobal()
#1791437 C0 3.463156s                     + Frame::SetElement() { #8140
#1791438 C0 3.463156s                       + ID::Offset() { #14021
#1791439 C0 3.463158s                         } // ID::Offset()
#1791440 C0 3.463160s                       + Frame::SetElement() { #8718
#1791441 C0 3.463161s                         } // Frame::SetElement()
#1791442 C0 3.463164s                       } // Frame::SetElement()
#1791443 C0 3.463165s                     } // NameExpr::Assign()
#1791444 C0 3.463167s                   } // IncrExpr::Eval()
#1791445 C0 3.463169s                 + ExprStmt::DoExec() { #608
#1791446 C0 3.463169s                   } // ExprStmt::DoExec()
#1791447 C0 3.463171s                 } // ExprStmt::Exec()
#1791448 C0 3.463173s               + post_execute_stmt() { #9791
#1791449 C0 3.463174s                 } // post_execute_stmt()
#1791450 C0 3.463176s               + Frame::HasDelayed() { #1626
#1791451 C0 3.463177s                 } // Frame::HasDelayed()
#1791452 C0 3.463179s               } // StmtList::Exec()                  // <-- outer 1st foo() call end
#1791453 C0 3.463181s             + BinaryExpr::Eval() { #148              // <-- ++x eval start
#1791454 C0 3.463182s               + Expr::IsError() { #10607
#1791455 C0 3.463183s                 + BroType::Tag() { #136051
#1791456 C0 3.463185s                   } // BroType::Tag()
#1791457 C0 3.463187s                 } // Expr::IsError()
#1791458 C0 3.463189s               + NameExpr::Eval() { #7901
#1791459 C0 3.463189s                 + ID::AsType() { #7946
#1791460 C0 3.463191s                   } // ID::AsType()
#1791461 C0 3.463193s                 + ID::IsGlobal() { #8005
#1791462 C0 3.463194s                   } // ID::IsGlobal()
#1791463 C0 3.463196s                 + Frame::GetElement() { #5882
#1791464 C0 3.463197s                   + ID::Offset() { #14022
#1791465 C0 3.463198s                     } // ID::Offset()
#1791466 C0 3.463201s                   } // Frame::GetElement()
#1791467 C0 3.463202s                 } // NameExpr::Eval()
#1791468 C0 3.463204s               + ConstExpr::Eval() { #450
#1791469 C0 3.463205s                 + ConstExpr::Value() { #450
#1791470 C0 3.463206s                   } // ConstExpr::Value()
#1791471 C0 3.463208s                 } // ConstExpr::Eval()
#1791472 C0 3.463210s               + is_vector() { #9674
#1791473 C0 3.463211s                 + BroType::Tag() { #136052
#1791474 C0 3.463212s                   } // BroType::Tag()
#1791475 C0 3.463215s                 } // is_vector()
#1791476 C0 3.463216s               + is_vector() { #9675
#1791477 C0 3.463217s                 + BroType::Tag() { #136053
#1791478 C0 3.463218s                   } // BroType::Tag()
#1791479 C0 3.463221s                 } // is_vector()
#1791480 C0 3.463222s               + Expr::Type() { #1833
#1791481 C0 3.463223s                 } // Expr::Type()
#1791482 C0 3.463225s               + BroType::Tag() { #136054
#1791483 C0 3.463226s                 } // BroType::Tag()
#1791484 C0 3.463228s               + IsVector() { #151
#1791485 C0 3.463229s                 } // IsVector()
#1791486 C0 3.463231s               + BinaryExpr::Fold() { #9
#1791487 C0 3.463232s                 + BroType::InternalType() { #39591
#1791488 C0 3.463233s                   } // BroType::InternalType()
#1791489 C0 3.463236s                 + BroType::Tag() { #136055
#1791490 C0 3.463236s                   } // BroType::Tag()
#1791491 C0 3.463241s                 + BroType::IsSet() { #4378
#1791492 C0 3.463242s                   } // BroType::IsSet()
#1791493 C0 3.463244s                 + BroType::InternalType() { #39592
#1791494 C0 3.463245s                   } // BroType::InternalType()
#1791495 C0 3.463247s                 + BroType::InternalType() { #39593
#1791496 C0 3.463248s                   } // BroType::InternalType()
#1791497 C0 3.463250s                 + BroType::Tag() { #136056
#1791498 C0 3.463251s                   } // BroType::Tag()
#1791499 C0 3.463253s                 + IsVector() { #152
#1791500 C0 3.463254s                   } // IsVector()
#1791501 C0 3.463256s                 + BroType::Tag() { #136057
#1791502 C0 3.463257s                   } // BroType::Tag()
#1791503 C0 3.463259s                 + BroType::InternalType() { #39594
#1791504 C0 3.463260s                   } // BroType::InternalType()
#1791505 C0 3.463262s                 + BroType::InternalType() { #39595
#1791506 C0 3.463263s                   } // BroType::InternalType()
#1791507 C0 3.463265s                 + BroType::Tag() { #136058
#1791508 C0 3.463266s                   } // BroType::Tag()
#1791509 C0 3.463268s                 + ValManager::GetBool() { #24561
#1791510 C0 3.463269s                   } // ValManager::GetBool()
#1791511 C0 3.463271s                 } // BinaryExpr::Fold()
#1791512 C0 3.463273s               } // BinaryExpr::Eval()                // <-- ++x eval end
#1791513 C0 3.463274s             + BroType::Tag() { #136059
#1791514 C0 3.463275s               } // BroType::Tag()
#1791515 C0 3.463278s             + StmtList::Exec() { #4501               // <-- outer 2nd foo() call end
```

Here's a quick and dirty Perl script to analyze the above snippet:
```
$ cat cwrap-prof.pl
use strict;

my $h;
my $acc;
my $totals;
my $indent = -1;
while (<stdin>) {
    chomp;
    #debug printf qq[%s\n], $_;
    if (m~ ([\d\.]+)s .* \+ (.*?)\(\) \{~) {
	my ($t, $f) = ($1, $2);
	#debug printf qq[- %f %s\n], $t, $f;
	die if (exists $h->{$f});
	$indent ++;
	$h->{$indent}{$f} = $t;
    }
    elsif (m~ ([\d\.]+)s .* \} // (.*?)\(\)~) {
	my ($t, $f) = ($1, $2);
	die if (not exists $h->{$indent}{$f});
	my $t_elapsed = $t - $h->{$indent}{$f};
	printf qq[- tree, sub calls: incl., excl.; %fs, %fs, %fs: %s+ %s()\n], $t_elapsed, $acc->{$indent}, $t_elapsed - $acc->{$indent}, '  ' x $indent, $f;
	$totals->{$f}{calls} ++;
	$totals->{$f}{time_excl_sub_calls} += $t_elapsed - $acc->{$indent};
	delete $acc->{$indent};
	delete $h->{$indent}{$f};
	$indent --;
	$acc->{$indent} += $t_elapsed;
    }
}
my $grand_total_time;
my $grand_total_calls;
my $sorted_totals;
foreach my $f (keys %{ $totals }) {
    $grand_total_time += $totals->{$f}{time_excl_sub_calls};
    $grand_total_calls += $totals->{$f}{calls};
    my $time_calls_func = sprintf qq[%fs for %3u calls (excl. sub calls) to %s()], $totals->{$f}{time_excl_sub_calls}, $totals->{$f}{calls}, $f;
    $sorted_totals->{$time_calls_func} ++;
}
foreach my $time_calls_func (sort keys %{ $sorted_totals }) {
    my ($time_excl_sub_calls) = $time_calls_func =~ m~^([\d\.]+)s~;
    printf qq[- %5.1f%%: %s\n], $time_excl_sub_calls / $grand_total_time * 100, $time_calls_func;
}
printf qq[- 100.0%: %fs for %3u calls (excl. sub calls) to *() AKA grand total\n], $grand_total_time, $grand_total_calls;
```

Running the Perl script results in the following output:

Note: The output is a little confusing because the time each function took is only shown when the function ends, to save lines.

Note: Elapsed timing in seconds is calculated in three different ways:

The 1st column shows the wallclock elapsed time including the function call, and including the time for any sub calls made.

The 2nd column shows the wallclock elapsed time excluding the function call, but including the time for any sub calls made.

The 3rd column shows the wallclock elapsed time including the function call, but excluding the time for any sub calls made.
```
$ egrep --max-count 1 --before-context=42 --after-context=247 foo cwrap.out | perl cwrap-prof.pl
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:   + Stmt::RegisterAccess()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:   + Frame::SetNextStmt()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:   + pre_execute_stmt()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:     + Stmt::RegisterAccess()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000006s, 0.000001s, 0.000005s:       + Expr::IsError()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:       + Frame::GetTrigger()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:         + ID::AsType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + ID::ID_Val()
- tree, sub calls: incl., excl.; 0.000013s, 0.000004s, 0.000009s:       + NameExpr::Eval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + ListExpr::Exprs()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + safe_malloc()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + ConstExpr::Value()
- tree, sub calls: incl., excl.; 0.000005s, 0.000002s, 0.000003s:         + ConstExpr::Eval()
- tree, sub calls: incl., excl.; 0.000014s, 0.000006s, 0.000008s:       + eval_list()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:       + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:       + Frame::GetCall()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:       + Frame::SetCall()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + SegmentProfiler::SegmentProfiler()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + plugin::Manager::HavePluginForHook()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:             + BroType::AsFuncType()
- tree, sub calls: incl., excl.; 0.000006s, 0.000002s, 0.000004s:           + Func::FType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:           + FuncType::Flavor()
- tree, sub calls: incl., excl.; 0.000011s, 0.000007s, 0.000004s:         + Func::Flavor()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + Func::HandlePluginResult()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + BroObj::BroObj()
- tree, sub calls: incl., excl.; 0.000006s, 0.000002s, 0.000004s:         + Frame::Frame()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + Frame::GetTrigger()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + Frame::ClearTrigger()
- tree, sub calls: incl., excl.; 0.000005s, 0.000002s, 0.000003s:         + Frame::SetTrigger()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + Frame::GetCall()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + Frame::SetCall()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + Frame::GetCall()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + TraceState::DoTrace()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + Frame::NthElement()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + Frame::SetElement()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + Frame::Reset()
- tree, sub calls: incl., excl.; 0.000003s, 0.000000s, 0.000003s:           + Stmt::RegisterAccess()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:           + Frame::SetNextStmt()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:           + pre_execute_stmt()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:             + Stmt::RegisterAccess()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:               + ID::AsType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:               + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:                 + ID::Offset()
- tree, sub calls: incl., excl.; 0.000004s, 0.000002s, 0.000002s:               + Frame::GetElement()
- tree, sub calls: incl., excl.; 0.000015s, 0.000006s, 0.000009s:             + NameExpr::Eval()
- tree, sub calls: incl., excl.; 0.000021s, 0.000016s, 0.000005s:           + ReturnStmt::Exec()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:             + Frame::BreakBeforeNextStmt()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:             + Frame::BreakOnReturn()
- tree, sub calls: incl., excl.; 0.000008s, 0.000002s, 0.000006s:           + post_execute_stmt()
- tree, sub calls: incl., excl.; 0.000045s, 0.000032s, 0.000013s:         + StmtList::Exec()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + Frame::HasDelayed()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:             + BroType::AsFuncType()
- tree, sub calls: incl., excl.; 0.000006s, 0.000002s, 0.000004s:           + Func::FType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:           + FuncType::Flavor()
- tree, sub calls: incl., excl.; 0.000010s, 0.000006s, 0.000004s:         + Func::Flavor()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:             + BroType::AsFuncType()
- tree, sub calls: incl., excl.; 0.000005s, 0.000002s, 0.000003s:           + Func::FType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:           + FuncType::Flavor()
- tree, sub calls: incl., excl.; 0.000011s, 0.000005s, 0.000006s:         + Func::Flavor()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:           + BroType::AsFuncType()
- tree, sub calls: incl., excl.; 0.000005s, 0.000001s, 0.000004s:         + Func::FType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + FuncType::YieldType()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + BroType::AsFuncType()
- tree, sub calls: incl., excl.; 0.000004s, 0.000002s, 0.000002s:         + Func::FType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + FuncType::YieldType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + TraceState::DoTrace()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + Frame::Release()
- tree, sub calls: incl., excl.; 0.000171s, 0.000104s, 0.000067s:       + BroFunc::Call()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:       + Frame::SetCall()
- tree, sub calls: incl., excl.; 0.000227s, 0.000208s, 0.000019s:     + CallExpr::Eval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + ExprStmt::DoExec()
- tree, sub calls: incl., excl.; 0.000236s, 0.000230s, 0.000006s:   + ExprStmt::Exec()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:   + post_execute_stmt()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:   + Frame::HasDelayed()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:   + Frame::SetNextStmt()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:   + pre_execute_stmt()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + Stmt::RegisterAccess()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:           + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000006s, 0.000001s, 0.000005s:         + Expr::IsError()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + ID::AsType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:           + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:             + ID::Offset()
- tree, sub calls: incl., excl.; 0.000005s, 0.000002s, 0.000003s:           + Frame::GetElement()
- tree, sub calls: incl., excl.; 0.000014s, 0.000008s, 0.000006s:         + NameExpr::Eval()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000004s, 0.000002s, 0.000002s:         + is_vector()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + UnaryExpr::Fold()
- tree, sub calls: incl., excl.; 0.000033s, 0.000024s, 0.000009s:       + UnaryExpr::Eval()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:         + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000004s, 0.000002s, 0.000002s:       + is_vector()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:         + BroType::InternalType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + BroType::InternalType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + Expr::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + Expr::Type()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + IsVector()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:         + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + ValManager::GetCount()
- tree, sub calls: incl., excl.; 0.000028s, 0.000004s, 0.000024s:       + IncrExpr::DoSingleEval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + ID::Offset()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:           + Frame::SetElement()
- tree, sub calls: incl., excl.; 0.000008s, 0.000003s, 0.000005s:         + Frame::SetElement()
- tree, sub calls: incl., excl.; 0.000014s, 0.000009s, 0.000005s:       + NameExpr::Assign()
- tree, sub calls: incl., excl.; 0.000087s, 0.000079s, 0.000008s:     + IncrExpr::Eval()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:     + ExprStmt::DoExec()
- tree, sub calls: incl., excl.; 0.000096s, 0.000088s, 0.000008s:   + ExprStmt::Exec()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:   + post_execute_stmt()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:   + Frame::HasDelayed()
- tree, sub calls: incl., excl.; 0.000365s, 0.000336s, 0.000029s: + StmtList::Exec()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:     + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000005s, 0.000002s, 0.000003s:   + Expr::IsError()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:     + ID::AsType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:       + ID::Offset()
- tree, sub calls: incl., excl.; 0.000005s, 0.000001s, 0.000004s:     + Frame::GetElement()
- tree, sub calls: incl., excl.; 0.000013s, 0.000008s, 0.000005s:   + NameExpr::Eval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + ConstExpr::Value()
- tree, sub calls: incl., excl.; 0.000004s, 0.000001s, 0.000003s:   + ConstExpr::Eval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000005s, 0.000001s, 0.000004s:   + is_vector()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000005s, 0.000001s, 0.000004s:   + is_vector()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:   + Expr::Type()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:   + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:   + IsVector()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::InternalType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:     + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::IsSet()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::InternalType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::InternalType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + IsVector()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::InternalType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::InternalType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + BroType::Tag()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + ValManager::GetBool()
- tree, sub calls: incl., excl.; 0.000040s, 0.000011s, 0.000029s:   + BinaryExpr::Fold()
- tree, sub calls: incl., excl.; 0.000092s, 0.000075s, 0.000017s: + BinaryExpr::Eval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s: + BroType::Tag()
-   0.0%: 0.000000s for   1 calls (excl. sub calls) to Expr::Tag()
-   0.0%: 0.000000s for   1 calls (excl. sub calls) to Frame::BreakOnReturn()
-   0.0%: 0.000000s for   1 calls (excl. sub calls) to Frame::Release()
-   0.0%: 0.000000s for   1 calls (excl. sub calls) to Func::HandlePluginResult()
-   0.0%: 0.000000s for   1 calls (excl. sub calls) to SegmentProfiler::SegmentProfiler()
-   0.0%: 0.000000s for   1 calls (excl. sub calls) to UnaryExpr::Fold()
-   0.0%: 0.000000s for   1 calls (excl. sub calls) to safe_malloc()
-   0.0%: 0.000000s for   2 calls (excl. sub calls) to FuncType::YieldType()
-   0.0%: 0.000000s for   3 calls (excl. sub calls) to Frame::SetNextStmt()
-   0.0%: 0.000000s for   3 calls (excl. sub calls) to pre_execute_stmt()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to BroType::IsSet()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to Frame::NthElement()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to Frame::Reset()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to ID::ID_Val()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to ListExpr::Exprs()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to ValManager::GetBool()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to ValManager::GetCount()
-   0.2%: 0.000001s for   1 calls (excl. sub calls) to plugin::Manager::HavePluginForHook()
-   0.2%: 0.000001s for   2 calls (excl. sub calls) to ExprStmt::DoExec()
-   0.2%: 0.000001s for   2 calls (excl. sub calls) to TraceState::DoTrace()
-   0.2%: 0.000001s for   3 calls (excl. sub calls) to Frame::SetCall()
-   0.2%: 0.000001s for   3 calls (excl. sub calls) to FuncType::Flavor()
-   0.4%: 0.000002s for   1 calls (excl. sub calls) to BroObj::BroObj()
-   0.4%: 0.000002s for   1 calls (excl. sub calls) to Frame::BreakBeforeNextStmt()
-   0.4%: 0.000002s for   1 calls (excl. sub calls) to Frame::ClearTrigger()
-   0.4%: 0.000002s for   2 calls (excl. sub calls) to Expr::Type()
-   0.4%: 0.000002s for   2 calls (excl. sub calls) to Frame::GetTrigger()
-   0.4%: 0.000002s for   3 calls (excl. sub calls) to Frame::GetCall()
-   0.4%: 0.000002s for   3 calls (excl. sub calls) to Frame::HasDelayed()
-   0.4%: 0.000002s for   3 calls (excl. sub calls) to IsVector()
-   0.7%: 0.000003s for   1 calls (excl. sub calls) to Frame::SetTrigger()
-   0.7%: 0.000003s for   2 calls (excl. sub calls) to ConstExpr::Value()
-   0.9%: 0.000004s for   1 calls (excl. sub calls) to Frame::Frame()
-   0.9%: 0.000004s for   5 calls (excl. sub calls) to ID::IsGlobal()
-   1.1%: 0.000005s for   1 calls (excl. sub calls) to NameExpr::Assign()
-   1.1%: 0.000005s for   1 calls (excl. sub calls) to ReturnStmt::Exec()
-   1.3%: 0.000006s for   2 calls (excl. sub calls) to ConstExpr::Eval()
-   1.3%: 0.000006s for   3 calls (excl. sub calls) to Frame::SetElement()
-   1.5%: 0.000007s for   3 calls (excl. sub calls) to post_execute_stmt()
-   1.5%: 0.000007s for   4 calls (excl. sub calls) to ID::Offset()
-   1.5%: 0.000007s for   7 calls (excl. sub calls) to BroType::InternalType()
-   1.7%: 0.000008s for   1 calls (excl. sub calls) to IncrExpr::Eval()
-   1.7%: 0.000008s for   1 calls (excl. sub calls) to eval_list()
-   1.7%: 0.000008s for   4 calls (excl. sub calls) to ID::AsType()
-   1.7%: 0.000008s for   5 calls (excl. sub calls) to Stmt::RegisterAccess()
-   2.0%: 0.000009s for   1 calls (excl. sub calls) to UnaryExpr::Eval()
-   2.0%: 0.000009s for   3 calls (excl. sub calls) to Frame::GetElement()
-   2.0%: 0.000009s for   5 calls (excl. sub calls) to BroType::AsFuncType()
-   2.6%: 0.000012s for   4 calls (excl. sub calls) to is_vector()
-   2.8%: 0.000013s for   3 calls (excl. sub calls) to Expr::IsError()
-   3.1%: 0.000014s for   2 calls (excl. sub calls) to ExprStmt::Exec()
-   3.1%: 0.000014s for   3 calls (excl. sub calls) to Func::Flavor()
-   3.7%: 0.000017s for   1 calls (excl. sub calls) to BinaryExpr::Eval()
-   3.7%: 0.000017s for   5 calls (excl. sub calls) to Func::FType()
-   3.7%: 0.000017s for  17 calls (excl. sub calls) to BroType::Tag()
-   4.1%: 0.000019s for   1 calls (excl. sub calls) to CallExpr::Eval()
-   5.2%: 0.000024s for   1 calls (excl. sub calls) to IncrExpr::DoSingleEval()
-   6.3%: 0.000029s for   1 calls (excl. sub calls) to BinaryExpr::Fold()
-   6.3%: 0.000029s for   4 calls (excl. sub calls) to NameExpr::Eval()
-   9.2%: 0.000042s for   2 calls (excl. sub calls) to StmtList::Exec()
-  14.6%: 0.000067s for   1 calls (excl. sub calls) to BroFunc::Call()
- 100.0%: 0.000458s for 144 calls (excl. sub calls) to *() AKA grand total
```

The bottom part of the output shows column 3 as a percentage of the Zeek script loop CPU time spent,
e.g. `NameExpr::Eval()` is called 4 times, and the total wallclock time for all calls added together excluding sub calls is 0.000029 seconds, or 6.3% of the total 0.000458 seconds for one Zeek script loop.

Interestingly we can see that the two top functions by percentage -- `BroFunc::Call()` [1] and `StmtList::Exec()` [2] -- only account for 3 of the 144 functions calls but account for about 25% of CPU usage excluding sub calls.
And the six top functions by percentage only account for 10 of the 144 function calls but account for about 46% of the CPU usage excluding sub calls.

The top functions look [1] [2] relatively innocent, so perhaps it's some kind of CPU background plumbing chewing the CPU? More investigation needed...

[1] https://github.com/zeek/zeek/blob/v3.1.2/src/Func.cc#L307
[2] https://github.com/zeek/zeek/blob/v3.1.2/src/Stmt.cc#L1517

And here are the 4 calls to `NameExpr::Eval()` which add up to 0.000029 seconds with the sub calls ignored:
```
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:         + ID::AsType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:         + ID::ID_Val()
- tree, sub calls: incl., excl.; 0.000013s, 0.000004s, 0.000009s:       + NameExpr::Eval()

- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:               + ID::AsType()
- tree, sub calls: incl., excl.; 0.000000s, 0.000000s, 0.000000s:               + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:                 + ID::Offset()
- tree, sub calls: incl., excl.; 0.000004s, 0.000002s, 0.000002s:               + Frame::GetElement()
- tree, sub calls: incl., excl.; 0.000015s, 0.000006s, 0.000009s:             + NameExpr::Eval()

- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:           + ID::AsType()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:           + ID::IsGlobal()
- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:             + ID::Offset()
- tree, sub calls: incl., excl.; 0.000005s, 0.000002s, 0.000003s:           + Frame::GetElement()
- tree, sub calls: incl., excl.; 0.000014s, 0.000008s, 0.000006s:         + NameExpr::Eval()

- tree, sub calls: incl., excl.; 0.000002s, 0.000000s, 0.000002s:     + ID::AsType()        // <-- called 1st by NameExpr::Eval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:     + ID::IsGlobal()      // <-- called 2nd by NameExpr::Eval()
- tree, sub calls: incl., excl.; 0.000001s, 0.000000s, 0.000001s:       + ID::Offset()      // <-- called     by Frame::GetElement()
- tree, sub calls: incl., excl.; 0.000005s, 0.000001s, 0.000004s:     + Frame::GetElement() // <-- called 3rd by NameExpr::Eval()
- tree, sub calls: incl., excl.; 0.000013s, 0.000008s, 0.000005s:   + NameExpr::Eval()
```
