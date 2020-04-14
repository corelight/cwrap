#include <stdio.h>
#include <stdlib.h>
#include "cpp-example-1.a.hpp"

#define INLINE inline __attribute__((always_inline))

extern        void clean_up(int * my_int);
              void bye_baz (void        ) { append_printf("called via atexit() via baz()\n"); }
              void bye     (void        ) { append_printf("called via atexit() via main()\n"); }
              int  baz     (int a       ) { atexit(bye_baz); params_printf("a=%d\n", a); int r =    (1 + a); result_printf("r=%d\n", r); return r; }
static INLINE int  bar     (int a       ) {                  params_printf("a=%d\n", a); int r = baz(1 + a); result_printf("r=%d\n", r); return r; }
static INLINE int  quux    (int a       ) {                                              int r =    (1 + a); result_printf("r=%d\n", r); return r; }
static        void qux     (void        ) { for (int i = 0; i < 3; i++) { quux(1 + i); } }

#ifdef __cplusplus
class Foo {
    private:
    my_struct my_struct_3;
#endif
    int my_private(int a) { params_printf("a=%d\n", a); int r = bar(1 + a); result_printf("r=%d\n", r); return r; }

#ifdef __cplusplus
    public:
    Foo(const char* arg1) : my_struct_3("my_struct_3", arg1) { append_printf(  "constructing Foo\n"); debug_printf("inside Foo\n");  }
    ~Foo()                                                   { append_printf("deconstructing Foo\n"); debug_printf("inside ~Foo\n");  }
#endif
    int my_public(int a) { params_printf("a=%d\n", a); debug_printf("hello my_public\n"); int r = my_private(1 + a); result_printf("r=%d\n", r); return r; }
#ifdef __cplusplus
};
#endif

#ifdef __cplusplus
my_struct my_struct_1("my_struct_1");
#endif

int main() {
    qux();
    for (int i = 0; i < 3; i++) {
        bar(i);
#ifdef CWRAP
        if (0 == i) {
            cwrap_log_verbosity_set("2=function~bar");
        }
#endif
    }
    atexit(bye);
    int my_int __attribute__ ((__cleanup__(clean_up))) = 1;
    my_int = 5;
    debug_printf("hello world\n");
    int b = baz(1);
#ifdef __cplusplus
    int x1 = 12345, y1 = 67890;
    get_max <int> (x1,y1);
    char x2 = 43, y2 = 21;
    get_max <char> (x2,y2);
    my_struct my_struct_2("my_struct_2");
    Foo foo_1("a");
    Foo foo_2("b");
    b = bar(foo_1.my_public(100));
#else
    b = bar(      my_public(100));
#endif
    result_printf("b=%d\n", b);
    return b;
}

