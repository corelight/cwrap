all: c---example-1.via-1-line.exe
	@echo - Makefile: 1 line: Running $<
	CWRAP_LOG_VERBOSITY_SET=1 CWRAP_LOG_STATS=1 ./$< 2>&1 | tee run.log
	CWRAP_LOG_VERBOSITY_SET=9:1=FUNCTION~my_ CWRAP_LOG_STATS=1 ./$< 2>&1 | tee --append run.log
	CWRAP_LOG_VERBOSITY_SET=1 CWRAP_LOG_STATS=1 CWRAP_LOG_QUIET_UNTIL=bye_baz ./$< 2>&1 | tee --append run.log

c---example-1.via-1-line.exe: c---example-1.*.c cpp-example-1.*.cpp cpp-example-1.*.hpp
	@echo - Makefile: 1 line: Building and linking $@
	$(CC) $(OPT) -Werror -g -o $@ c---example-1.*.c
