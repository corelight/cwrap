#include <stdio.h>
#include "cpp-example-1.a.hpp"

#ifdef __cplusplus
my_struct my_struct_2("my_struct_2");
#endif

void clean_up(int * my_int) { append_printf("my_int=%d\n", *my_int); }
