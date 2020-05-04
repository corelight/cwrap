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

Running cwrap instrumented `zeek --help`
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

Running cwrap instrumented `zeek hello.zeek`
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

There is a hard-coded limit in cwrap which disables function instrumentation output after 10,000 calls. After that, function calls are still counted as if the function verbosity would have caused output. This is a fail safe mechanism to help reduce output size:
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

