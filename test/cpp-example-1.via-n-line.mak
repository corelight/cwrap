all: cpp-example-1.via-n-line.exe
	@echo - Makefile: n line: Running $<
	CWRAP_LOG_VERBOSITY_SET=1 CWRAP_LOG_STATS=1 ./$< 2>&1 | tee run.log
	CWRAP_LOG_VERBOSITY_SET=9/1=FUNCTION-my_ CWRAP_LOG_STATS=1 ./$< 2>&1 | tee --append run.log
	CWRAP_LOG_VERBOSITY_SET=1 CWRAP_LOG_STATS=1 CWRAP_LOG_QUIET_UNTIL=bye_baz ./$< 2>&1 | tee --append run.log

cpp-example-1.a.o: cpp-example-1.a.cpp cpp-example-1.*.hpp
	@echo - Makefile: n lines: Building $@
	$(CC) $(OPT) -Werror -g -o $@ -c $<

cpp-example-1.b.o: cpp-example-1.b.cpp cpp-example-1.*.hpp
	@echo - Makefile: n lines: Building $@
	$(CC) $(OPT) -Werror -g -o $@ -c $<

cpp-example-1.via-n-line.exe: cpp-example-1.a.o cpp-example-1.b.o
	@echo - Makefile: n lines: Linking $@
	$(CC) -Werror -g -o $@ $^ -lstdc++

