cwrap assembler shenanigans
=========================

This document details some of the experimental and/or fragile issues regarding how cwrap operates internally.

Currently all the issues have to do with how cwrap processes the assembler output file from gcc.

Ideally, the issues could be resolved as follows:
- Brianstorm a different algorithm / approach to achive the same results.
- Create a plugin to modify the behavior of gcc to make life easier for cwrap.
- Modify the behavior of gcc to make life easier for cwrap.

Issue detecting gcc inserted entry and exit function calls
-----------

After C/C++ source code is compiled to an assembly language file by gcc, the individual functions are relatively easy to spot and look something like this:

```
_Z11safe_mallocm:
    movq    8(%rbp), %rax
    movq    %rax, %rsi
    movq    _Z11safe_mallocm@GOTPCREL(%rip), %rax
    movq    %rax, %rdi
...
    call    __cyg_profile_func_enter@PLT # <-- rsi & rdi are parameters
...
    movq    8(%rbp), %rax
    movq    %rax, %rsi
    movq    _Z11safe_mallocm@GOTPCREL(%rip), %rax
    movq    %rax, %rdi
...
    call    __cyg_profile_func_exit@PLT # <-- rsi & rdi are parameters
...
    ret
```

Looks simple enough but the following cause complications:
- The optimizer can cause a larger distance between the movq instructions and its associated call instruction.
- There can be a multiple and uneven number of enter and exit calls per function.
- The optimizer can change the register holding `_Z11safe_mallocm` address.
- The optimizer can inline multiple functions, so it's tricky to figure out which enter or exit function is associated with with function address stored in which register.
- There can be convoluted branching inside the function assembler, so the call can occur on line x, but the function address assigned to a register occurs on line x + y.

Possible solution:

This issue would get much simpler if e.g. each call had an assembler comment from gcc with the associated function name, e.g.:

```
    call    __cyg_profile_func_enter@PLT # _Z11safe_mallocm
```

This way it wouldn't be necassary for cwrap to try and reconcile function address and register assignment with calls to enter and exit functions.

Once cwrap detects the function name -- e.g. `_Z11safe_mallocm` -- then it converts it into a function unique data structure by prepend `cwrap_data_`, e.g. `cwrap_data__Z11safe_mallocm`.

Issue associating manually inserted instrumentation with current function
-----------

If the user elects to manually instrument a particular function using the e.g. `CWRAP_PARAMS()` macro, how does that macro:
- Determine which function it's currently running in, e.g. `_Z11safe_mallocm` ?
- Determine which cwrap data structure is associated with that function, e.g. `cwrap_data__Z11safe_mallocm` ?

This is tricky because there seems to be no very to get the mangled function name in the C++ source code at compile time.

The cloest we can get is the `__PRETTY_FUNCTION__` macro which provides the demangled function name.

So currently cwrap macros work as follows:
- Embed the `__PRETTY_FUNCTION__` so that the assembler contains it inline.
- cwrap finds the embedded `__PRETTY_FUNCTION__` demangled function name and tries to convert it to the mangled function name.
- Once cwrap has the mangled function name, it knows which function the macro is in and can prepend the `cwrap_data_` etc;

This mechanism works surprisingly well for very many functions but it's fragile.

Here's an example of function names where it didn't work out of the box:

Mangled name found in assembler: `_ZNK11RuleMatcher5MatchEP18RuleFileMagicStatePKhmPSt3mapIiSt3setINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4lessISB_ESaISB_EESt7greaterIiESaISt4pairIKiSF_EEE()`

Demangles to: `RuleMatcher::Match(RuleFileMagicState*, const unsigned char*, unsigned long, std::map<int, std::set<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, std::less<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::allocator<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > >, std::greater<int>, std::allocator<std::pair<const int, std::set<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, std::less<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::allocator<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > > > > >*) const`

But `__PRETTY_FUNCTION__` delivers: `RuleMatcher::Match(RuleFileMagicState*, const u_char*, uint64_t, RuleMatcher::MIME_Matches*) const`

Obviously the C++ demangler and `__PRETTY_FUNCTION__` are not 100% compatible.

Even worse, some mangled file names are incorrect mangled by gcc and cannot be demangled at all.

cwrap currently works around the above illustrated issue by:
- Munging any parameter containing `::` to the text `c_o_m_p_l_e_x_t_y_p_e` just so that it can match at all.
- Also, common types like `uint64_t` are converted to `unsigned long` so that it can match at all.

Possible solution:

This issue would get much simpler if a gcc equivalent to `__PRETTY_FUNCTION__` existed called e.g. `__MANGLED_FUNCTION__`.

In this case cwrap would never need to demangle and match to the mangled function names in the assembler files.
