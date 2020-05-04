#!/usr/bin/perl

# Copyright (c) 2012 Simon Hardy-Francis.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use strict;
use Cwd;
use Time::HiRes;
use List::MoreUtils qw(first_index indexes);
use File::Basename; # for fileparse()
use Test::More;
use FFI::Platypus::Lang::CPP::Demangle::XS;

if ($0 =~ m~test~) {
    # come here if required by cwrap-test.pl
    goto ONLY_REQUIRED_FOR_SUBS;
}

$| ++;

my $log;
my $cwd = getcwd;
my $ts  = Time::HiRes::time();

my $arguments = "";
for ( my $c = 0; $c < @ARGV; $c++ ) {
   my $tmp        =  $ARGV[$c];
      $tmp        =~ s~"~\\"~g;
      $arguments .= ' ' . $tmp;
}
$arguments =~ s~^\s+~~; # e.g. gcc -O0 -g -o c---example.via-1-line.exe c---example.1.c c---example.2.c

if    ($arguments =~ m~\.(cc|cpp|cxx|hpp|hxx)~ ) { $arguments = "g++ " . $arguments; } # e.g. compile line
elsif ($arguments =~ m~\+\+~                   ) { $arguments = "g++ " . $arguments; } # e.g. -std=c++17 or gnu++ or -nostdinc++ etc on link line
else                                             { $arguments = "gcc " . $arguments; }

my ($gcc_out_file) = $arguments =~ m~-o\s+([^\s]+)~;
my ($gcc_out_path,
    $gcc_out_name,
    $gcc_out_ext ) = get_path_name_and_ext($gcc_out_file) if (defined $gcc_out_file);

chomp(my $os_release = `cat /etc/os-release 2>&1 | egrep PRETTY`);

$log .= sprintf qq[%f - cwrap: timestamp   : %s AKA %f\n], Time::HiRes::time() - $ts, scalar localtime, Time::HiRes::time();
$log .= sprintf qq[%f - cwrap: os_release  : %s\n]       , Time::HiRes::time() - $ts, $os_release;
$log .= sprintf qq[%f - cwrap: arguments   : %s\n]       , Time::HiRes::time() - $ts, $arguments;
$log .= sprintf qq[%f - cwrap: cwd         : %s\n]       , Time::HiRes::time() - $ts, $cwd;
$log .= sprintf qq[%f - cwrap: gcc_out_file: %s\n]       , Time::HiRes::time() - $ts, $gcc_out_file;
$log .= sprintf qq[%f - cwrap: gcc_out_path: %s\n]       , Time::HiRes::time() - $ts, $gcc_out_path;
$log .= sprintf qq[%f - cwrap: gcc_out_name: %s\n]       , Time::HiRes::time() - $ts, $gcc_out_name;
$log .= sprintf qq[%f - cwrap: gcc_out_ext : %s\n]       , Time::HiRes::time() - $ts, $gcc_out_ext ;

my $cwrap_c = sprintf "%s.cwrap.c", $gcc_out_name; # generate one unique .cwrap.c file per binary output

if ($cwd =~ m~(/CMakeFiles/CMakeTmp|/CMakeFiles/.*/CompilerIdC)~) {
    # come here to compile cmake test programs without modifying the gcc command line
    my $gcc = $arguments;
    $log .= sprintf qq[%f - cwrap: unchanged: running: %s\n], Time::HiRes::time() - $ts, $gcc;
    my $output = `$gcc 2>&1`;
    my $exit_code = $? >> 8; # perldoc perlvar: the exit value of the subprocess is really ("$? >> 8")
    my $output_2_log = $output;
       $output_2_log = "<no output>\n" if ($output =~ m~^\s*$~s);
       $output_2_log .= sprintf "<exit(%d)>\n", $exit_code if ($output =~ m~^\s*$~s);
       $output_2_log =~ s~^(.*)$~> $1~gm;
    $log .= $output_2_log;
    $log .= sprintf qq[%f - cwrap: done with exit(%d)\n], Time::HiRes::time() - $ts, $exit_code;
    printf qq[%s], $output;
    exit($exit_code);
}

cwrap_die(sprintf qq[%f ERROR: cwrap cannot detect gcc -o command line option in arguments!\n], Time::HiRes::time() - $ts) if ($gcc_out_file =~ m~^$~);

my @argument_array = split(m~\s+~, $arguments);
my @source_file_arguments;
foreach my $argument (@argument_array) {
    if ($argument =~ m~\.(cpp|cxx|cc|hpp|hxx|h|c)$~) {
        push @source_file_arguments, $argument;
    }
}

my @exe_file_arguments;
if ($gcc_out_file !~ m~\.o$~) {
    push @exe_file_arguments, $gcc_out_file;
}

$log .= sprintf qq[%f - cwrap: source file arguments: %d (@source_file_arguments)\n], Time::HiRes::time() - $ts, scalar @source_file_arguments;
$log .= sprintf qq[%f - cwrap: exe    file arguments: %d (@exe_file_arguments)\n]   , Time::HiRes::time() - $ts, scalar @exe_file_arguments;

if (scalar @source_file_arguments > 0) {
    source_to_assembler_to_object_or_executable();
}

if ($gcc_out_ext =~ m~\.o~) {
    #$log .= sprintf qq[%f - cwrap: gcc arguments create object\n], Time::HiRes::time() - $ts;
}
else {
    if (0 == scalar @source_file_arguments) {
        $log .= sprintf qq[%f - cwrap: gcc arguments create executable\n], Time::HiRes::time() - $ts;
        my $gcc_4_exe = $arguments;
        assembler_to_object_or_executable_via_command($gcc_4_exe);
    }
}



sub END {
    # come here when Perl exits to write log file
    if ($gcc_out_name !~ m~^\s*$~) {
        $log .= sprintf qq[%f - cwrap: todo: implement cwrap_log_quiet_until_cw in manual instrumantation macros\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: move call count to function open line\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: figure out building with ninja instead of make\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: integrate home-grown, non-assembler corountines with cwrap\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: integrate third party, assembler coroutines with cwrap via generic API\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: mechanism to exclude arbitrary functions from instrumentation at compile time\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: logging to memory buffer to file\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: logging to memory buffer and only to file at exit\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: options to auto switch off function instrumentation if calls become too high at run-time\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: multi-threaded has been neglected up until now; finish off\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: try out cwrap with other open source C/C++ code bases\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: auto detect if trying to build without gcc and abort\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: implement cwrap for gcc for ARM\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: consider cloning __PRETTY_FUNCTION__ in gcc, to implement __MANGLED_FUNCTION__\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: consider building if(verbosity){..} mechanism into gcc -finstrument-functions option\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: consider adding performance option to replace if(verbosity){..} mechanism with jump switch\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: consider adding HTML run-time interface for easier browsing of run-time call-tree\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: consider keeping run-time performance stats\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: consider colored output to stdout\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: consider extra cwrap_log_init() functionality such as dump instrumentation info\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: add more scenarios to cwrap test, e.g. static and shared libraries\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: todo: do not remove -flto if file being ignored\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: done in %f seconds\n], Time::HiRes::time() - $ts, Time::HiRes::time() - $ts;
        my $log_file = sprintf "%s%s.cwrap.log", $gcc_out_name, $gcc_out_ext;
        open(my $out, '>', $log_file) || cwrap_die(sprintf qq[%s ERROR: cwrap: cannot open file for writing: %s\n], Time::HiRes::time() - $ts, $log_file);
        syswrite($out, $log, length($log));
        close $out;
    }
}

sub cwrap_die {
    my ($format) = shift @_;
    my $die_message = sprintf $format, @_;
    $log .= $die_message;
    die $die_message;
}

sub source_to_assembler_to_object_or_executable {
    my ($o_file)  =  $arguments =~ m~-o ([^\s]+)~;
    my  $gcc_2_s  =  $arguments;
        $gcc_2_s  =~ s~-o [^\s]+~-S -fPIC~; # fPIC needed if objects put into shared object?
        $gcc_2_s .=  qq[ -finstrument-functions -I. --include cwrap.h];
    create_cwrap_h_if_necessary();
    if ($gcc_2_s =~ s~\s+-flto(\s+)~$1~g) { # https://stackoverflow.com/questions/29972192/how-does-gccs-linktime-optimisation-flto-flag-work
        $log .= sprintf qq[%f - cwrap: c/cpp to assembler: note:: removed any -flto instances otherwise assembler output optimized\n], Time::HiRes::time() - $ts;
    }
       $log          .=  sprintf qq[%f - cwrap: c/cpp to assembler: running: %s\n], Time::HiRes::time() - $ts, $gcc_2_s;
    my $t1            =  Time::HiRes::time();
    my $output        =  `$gcc_2_s 2>&1`;
    my $t2            =  Time::HiRes::time();
    my $exit_code     =  $? >> 8; # perldoc perlvar: the exit value of the subprocess is really ("$? >> 8")
    my $output_2_log  =  $output;
       $output_2_log  =  "<no output>\n" if ($output =~ m~^\s*$~s);
       $output_2_log .=  sprintf "<exit(%d)> in %f seconds building assembler for %s\n", $exit_code, $t2 - $t1, $o_file;
       $output_2_log  =~ s~^(.*)$~> $1~gm;
       $log          .=  $output_2_log;
    if ($exit_code != 0) {
        $log .= sprintf qq[%f ERROR: cwrap: compilation to assembler has unexpected errors\n], Time::HiRes::time() - $ts;
        $log .= sprintf qq[%f - cwrap: done with exit(%d)\n], Time::HiRes::time() - $ts, $exit_code;
        printf qq[%s], $output;
        exit($exit_code);
    }

    $log .= sprintf qq[%f - cwrap: munging assembler files\n], Time::HiRes::time() - $ts;
    foreach my $source_file_argument (@source_file_arguments) {
        my ($path, $name, $exit) = get_path_name_and_ext($source_file_argument);
        my $s_file = $cwd . '/' . $name . '.s';

        read_modify_rewrite_assembler_file($s_file);
    } # foreach my $source_file_argument

    my $gcc_4_s = $arguments;
    foreach my $source_file_argument (@source_file_arguments) {
        my ($path, $name, $exit) = get_path_name_and_ext($source_file_argument);
        my $s_file = $cwd . '/' . $name . '.s';
        $gcc_4_s =~ s~$source_file_argument~$s_file.2.s~;
    } # foreach my $source_file_argument
    assembler_to_object_or_executable_via_command($gcc_4_s);
} # source_to_assembler_to_object_or_executable()

sub assembler_to_object_or_executable_via_command {
    my ($gcc_command) = @_;
    my ($o_file     )  =  $gcc_command =~ m~-o ([^\s]+)~;
    my  $output;
    my  $output_2_log;
    if ((0 == scalar @exe_file_arguments)    # if no undefined cwrap_data_* because assembling to object files, or
    ||  ($gcc_command =~ m~\-shared~    )) { # if no undefined cwrap_data_* because creating a shared object
        # come here if gxx operation results in no undefined cwrap_data_*
        if ($gcc_command =~ m~\-shared~) { # if .so loaded at run-time, this might happen before the regular call to cwrap_log_init(); this helps call cwrap_log_init() as early as possible
			# See https://gcc.gnu.org/legacy-ml/gcc-help/1999-11n/msg00029.html    <-- example using "__attribute__((constructor))" mechanism
            # See https://groups.google.com/forum/#!topic/gnu.gcc.help/Fit5UOU9UNs <-- why NOT to use "-Wl,-init,<function>" mechanism for shared object
            my $cwrap_so_c_file = $gcc_out_file . ".cwrap.c"; # e.g. "lib/libbroker.so.1.3"
            $log .= sprintf qq[%f - cwrap: creating cwrap constructor for .so file: %s\n], Time::HiRes::time() - $ts, $cwrap_so_c_file;
            my $new_file_contents = sprintf <<EOF;
#ifdef __cplusplus
extern "C" {
#endif

extern int cwrap_log_init(void);
extern int cwrap_log_init_so(void) __attribute__ ((constructor));

int cwrap_log_init_so(void) {
    return cwrap_log_init();
}

#ifdef __cplusplus
}
#endif
EOF

            open(my $out, '>', $cwrap_so_c_file) || cwrap_die(sprintf qq[%f ERROR: cwrap: cannot open file for writing: %s\n], Time::HiRes::time() - $ts, $cwrap_so_c_file);
            syswrite($out, $new_file_contents);
            close $out;

            my $cc_command    = sprintf qq[gcc -c -fPIC -o %s.o %s], $cwrap_so_c_file, $cwrap_so_c_file;
               $log          .= sprintf qq[%f - cwrap: compile cwrap so constructor: running: %s\n], Time::HiRes::time() - $ts, $cc_command;
            my $t1            = Time::HiRes::time();
               $output        = `$cc_command 2>&1`;
            my $t2            = Time::HiRes::time();
            my $exit_code     =  $? >> 8; # perldoc perlvar: the exit value of the subprocess is really ("$? >> 8")
               $output_2_log  =  $output;
               $output_2_log  =  "<no output>\n" if ($output =~ m~^\s*$~s);
               $output_2_log .=  sprintf "<exit(%d)> in %f seconds building object for %s\n", $exit_code, $t2 - $t1, $cwrap_c;
               $output_2_log  =~ s~^(.*)$~> $1~gm;
            if ($exit_code != 0) {
                $log .= $output_2_log;
                $log .= sprintf qq[%f ERROR: cwrap: compilation to object or executable has unexpected errors\n], Time::HiRes::time() - $ts;
                $log .= sprintf qq[%f - cwrap: done with exit(%d)\n], Time::HiRes::time() - $ts, $exit_code;
                printf qq[%s], $output;
                exit($exit_code);
            }
            $log .= $output_2_log;

            $gcc_command =~ s~^([^ ]+) ~$1 $cwrap_so_c_file.o ~; # order important: insert as the very first file to be linked! so that the cwrap constructor is the first to be called at run-time!
        }

           $log          .= sprintf qq[%f - cwrap: no undefined cwrap_data_*: running: %s\n], Time::HiRes::time() - $ts, $gcc_command;
        my $t1            = Time::HiRes::time();
           $output        =  `$gcc_command 2>&1`;
        my $t2            = Time::HiRes::time();
        my $exit_code     =  $? >> 8; # perldoc perlvar: the exit value of the subprocess is really ("$? >> 8")
           $output_2_log  =  $output;
           $output_2_log  =  "<no output>\n" if ($output =~ m~^\s*$~s);
           $output_2_log .=  sprintf "<exit(%d)> in %f seconds building object or shared object for %s\n", $exit_code, $t2 - $t1, $o_file;
           $output_2_log  =~ s~^(.*)$~> $1~gm;
    }
    else {
        # come here if linking object files into a binary causing undefined cwrap_data_*
        my $output_type;
        if (scalar @source_file_arguments > 0) { # if compiling to binary directly from source files
            $log .= sprintf qq[%f - cwrap: object to binary #1: running via gxx (because source files detected): %s\n], Time::HiRes::time() - $ts, $gcc_command;
            $output = `$gcc_command 2>&1`;
            $output_type = 'gxx';
            cwrap_die(sprintf qq[%f ERROR: detected errors in gxx output:\n%s\n], Time::HiRes::time() - $ts, $output) if ($output =~ m~:\d+: Error: ~is);
        }
        else {
            # use nm instead of gcc/g++ because nm takes about 0.07 seconds instead of over 75 seconds for gcc/g++ !!!
            $log .= sprintf qq[%f - cwrap: constructing two nm commands from gcc command\n], Time::HiRes::time() - $ts;
            # Why two nm commands? Because second one uses --dynamic option:
            # https://stackoverflow.com/questions/54052534/why-nm-libc-so-reports-no-symbols
            # https://stackoverflow.com/questions/15345543/when-to-use-dynamic-option-in-nm
            undef $output;
            foreach my $nm_command_number (1..2) {
                my $nm_command  = qq[nm --print-file-name --no-sort --undefined-only];
                   $nm_command .= qq[ --dynamic] if (2 == $nm_command_number);
                my @gcc_command_parts = split(m~\s+~, $gcc_command);
                foreach my $gcc_command_part (@gcc_command_parts) {
                    if ($gcc_command_part =~ m~^\@~) { # e.g. @CMakeFiles/zeek.dir/objects1.rsp <-- hopefully containing lots of object files
                        # fall thru to append
                    }
                    elsif (($gcc_command_part =~ m~^\-~                )    # e.g. -Wl,-soname,libcaf_core.so.0.17.3
                    ||  ($gcc_command_part !~ m~\.(o|a|so[\.0-9]*)$~)) { # e.g. logging/writers/sqlite/CMakeFiles/plugin-Zeek-SQLiteWriter.dir/sqlite.bif.init.cc.o ../aux/paraglob/src/ahocorasick/libahocorasick.a ../aux/broker/lib/./libcaf_openssl.so ../aux/broker/lib/libbroker.so.1.2
                        $log .= sprintf qq[%f - cwrap: discarding gcc command  line option: %s\n], Time::HiRes::time() - $ts, $gcc_command_part;
                        goto SKIP_APPEND;
                    }
                    # come here to append gcc command part to nm command
                    $nm_command .= ' ' . $gcc_command_part;
                    SKIP_APPEND:;
                }
                $nm_command .= qq[ 2>&1 | egrep cwrap_data_];
                $log .= sprintf qq[%f - cwrap: object to binary #1: running via nm #%d (because no source files detected and nm faster than gxx): %s\n], Time::HiRes::time() - $ts, $nm_command_number, $nm_command;
                $output .= `$nm_command 2>&1`;
            }
            $output_type = 'nm';
        }

        $log .= sprintf qq[%f - cwrap: using undefines from %s; auto generating: %s\n], Time::HiRes::time() - $ts, $output_type, $cwrap_c;
        using_undefind_error_write_cwrap_c($output, $output_type);

        my $cc_command    = sprintf qq[gcc -c -fPIC -o %s.o %s -Wl,--undefined,cwrap_log_init], $cwrap_c, $cwrap_c; # todo: consider using -Wl,--whole-archive
        my @gcc_command_parts = split(m~\s+~, $gcc_command);
        foreach my $gcc_command_part (@gcc_command_parts) {
            $cc_command .= ' ' . $gcc_command_part if ($gcc_command_part =~ m~-DCWRAP~); # append any CWRAP compile defaults
        }
           $log          .= sprintf qq[%f - cwrap: compile cwrap: running: %s\n], Time::HiRes::time() - $ts, $cc_command;
        my $t1            = Time::HiRes::time();
           $output        = `$cc_command 2>&1`;
        my $t2            = Time::HiRes::time();
        my $exit_code     =  $? >> 8; # perldoc perlvar: the exit value of the subprocess is really ("$? >> 8")
           $output_2_log  =  $output;
           $output_2_log  =  "<no output>\n" if ($output =~ m~^\s*$~s);
           $output_2_log .=  sprintf "<exit(%d)> in %f seconds building object for %s\n", $exit_code, $t2 - $t1, $cwrap_c;
           $output_2_log  =~ s~^(.*)$~> $1~gm;
        if ($exit_code != 0) {
            $log .= $output_2_log;
            $log .= sprintf qq[%f ERROR: cwrap: compilation to object or executable has unexpected errors\n], Time::HiRes::time() - $ts;
            $log .= sprintf qq[%f - cwrap: done with exit(%d)\n], Time::HiRes::time() - $ts, $exit_code;
            printf qq[%s], $output;
            exit($exit_code);
        }
        $log .= $output_2_log;

        # see https://en.wikipedia.org/wiki/Gold_%28linker%29
           $gcc_command  .= sprintf qq[ %s.o -Wl,--undefined,cwrap_log_init -fPIC -lunwind], $cwrap_c;
           $gcc_command  .= qq[ -fuse-ld=gold] if ($os_release !~ m~Alpine~i); # gold linker seems dodgy on Alpine Linux
           $log          .= sprintf qq[%f - cwrap: object to binary #2: running: %s\n], Time::HiRes::time() - $ts, $gcc_command;
        my $t1            = Time::HiRes::time();
           $output        = `$gcc_command 2>&1`;
        my $t2            = Time::HiRes::time();
        my $exit_code     =  $? >> 8; # perldoc perlvar: the exit value of the subprocess is really ("$? >> 8")
           $output_2_log  =  $output;
           $output_2_log  =  "<no output>\n" if ($output =~ m~^\s*$~s);
           $output_2_log .=  sprintf "<exit(%d)> in %f seconds building binary for %s\n", $exit_code, $t2 - $t1, $o_file;
           $output_2_log  =~ s~^(.*)$~> $1~gm;
        if ($exit_code != 0) {
            $log .= $output_2_log;
            $log .= sprintf qq[%f ERROR: cwrap: compilation to object or executable has unexpected errors\n], Time::HiRes::time() - $ts;
            $log .= sprintf qq[%f - cwrap: done with exit(%d)\n], Time::HiRes::time() - $ts, $exit_code;
            printf qq[%s], $output;
            exit($exit_code);
        }
    }
    $log .= $output_2_log;
    printf qq[%s], $output;
} # assembler_to_object_or_executable_via_command()

sub get_path_name_and_ext {
   my ($path_name_ext) = @_;
   #debug $log .= sprintf qq[debug: (?, ?, ?)=fileparse(%s)\n], $path_name_ext;
   my ($f, $path, $s)  = fileparse($path_name_ext, "", qr/\.[^.]*/); # suffix maybe nothing or .something
       $path           = '' if ($path eq './');
   my  $name           =  $f                    ; # e.g. 'connection'   in    'connection.o'
   my  $ext            =  $s                    ; # e.g.           '.o' in    'connection.o'
   #debug $log .= sprintf qq[debug: ($f, $d, $s)=fileparse(%s) // %s=path %s=name %s=ext\n], $path_name_ext, $folder, $name, $ext;
   return ($path, $name, $ext);
} # get_path_name_and_ext()

sub pretty_asm {
    my ($asm_line) = @_;
        $asm_line =~ s~\t~ ~gs;
        $asm_line =~ s~^\s+~~s;
        $asm_line =~ s~\s+$~~s;
    return $asm_line;
}

# e.g. these types are the same but out of order:
#      my_func(const unsigned char*, long unsigned int, unsigned char*)
#      my_func(unsigned char const*, unsigned long, unsigned char*)
sub demangle_name_sanitize_type_order {
    my ($demangled_name) = @_;
    $demangled_name =~ s~(char|short|int|long|float|double) (unsigned|signed)~$2 $1~g; # todo: figure out a better way to order types
    while ($demangled_name =~ s~(unsigned|signed|char|short|int|long|float|double) const~const $1~g) {} # todo: figure out a better way to order types
    $demangled_name =~ s~(long) int\s*~$1~g; # 'long int' same as 'long'; see: https://stackoverflow.com/questions/17287957/is-long-unsigned-as-valid-as-unsigned-long-in-c
    return $demangled_name;
}

sub demangle_name {
    my ( $mangled_name) = @_;
    my $demangled_name;
    if ( $mangled_name =~ m~^_Z~) {
        # first try with Perl inline demangler which only seems to work on 99%+ mangled names, but it's fast :-)
        $demangled_name = FFI::Platypus::Lang::CPP::Demangle::XS::demangle($mangled_name) if($mangled_name =~ m~^_Z~); # faster and more scalable than c++filt or llvm-cppfilt
        goto GOT_DEMANGLED_NAME if (($mangled_name ne $demangled_name) && (length($demangled_name) > 0));

        # try with c++filt which has the command line option --no-recursion-limit:
        my $cxx_filt_command = sprintf qq[c++filt --no-recursion-limit %s], $mangled_name;
        $demangled_name = `$cxx_filt_command`;
        chomp $demangled_name;
        $log .= sprintf qq[%f   - cwrap: ran %s giving %s\n], Time::HiRes::time() - $ts, $cxx_filt_command, $demangled_name;
        goto GOT_DEMANGLED_NAME if (($mangled_name ne $demangled_name) && (length($demangled_name) > 0));

        # try with llvm-cxxfilt which seems a little more reliable and consistent than c++filt from gcc:
        my $llvm_cxx_filt_command = sprintf qq[llvm-cxxfilt %s], $mangled_name;
        $demangled_name = `$llvm_cxx_filt_command`;
        chomp $demangled_name;
        $log .= sprintf qq[%f   - cwrap: ran %s giving %s\n], Time::HiRes::time() - $ts, $llvm_cxx_filt_command, $demangled_name;
        goto GOT_DEMANGLED_NAME if (($mangled_name ne $demangled_name) && (length($demangled_name) > 0));

        # own KISS demangling... obviously this is not good... why can CXX simply not demangle properly?!
        my ($len, $rest);
        $rest = $mangled_name;
        $rest =~ s~^[^\d]+~~;
        my @name_parts;
        push @name_parts, 'CWRAP_DEMANGLE_FAIL';
        while ($rest =~ m~^(\d+)(.*)$~) {
            ($len, $rest) = ($1, $2);
            my $name_part = substr($rest, 0, $len);
            push @name_parts, $name_part;
            #debug printf qq[- %d bytes: %s in %s\n\n], $len, $name_part, $rest;
            substr($rest, 0, $len) = '';
        }
        $demangled_name = join('::', @name_parts);
        $log .= sprintf qq[%f WARNING: internal: failed to demangle name using c++filt or llvm-cxxfilt: %s\n], Time::HiRes::time() - $ts, $mangled_name;

        GOT_DEMANGLED_NAME:;
        $demangled_name = demangle_name_sanitize_type_order($demangled_name);
    }
    else {
        $demangled_name = $mangled_name;
    }
    cwrap_die sprintf qq[%f ERROR: internal: unexpected zero length demangled name from mangled name: %s\n], Time::HiRes::time() - $ts, $mangled_name if (0 == length($demangled_name));
    return $demangled_name;
}

sub match_enter_exit_with_mangled_names {
    my $a = shift;
    my $z = shift;
    my $func_lines_ref = shift;
    $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: searching in %d lines %d to %d of %d lines in file\n], Time::HiRes::time() - $ts, $z - $a + 1, $a, $z, scalar @$func_lines_ref;

    # movq    my_private@GOTPCREL(%rip), %rax
    my @func_lines_min = grep(m~^\s*(\.L\d+|j[^\s]+\s+\.L\d+|(call|jmp)\s+__cyg_|leaq\s+[^\.\s].*rip|movq.*rip|ret\s+|movq\s+.*r.., %rdi)~, @$func_lines_ref[$a..$z]);
    unshift @func_lines_min, ".L000:\n";
    $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: squashed down to %d lines\n], Time::HiRes::time() - $ts, scalar @func_lines_min;

    my $h;
    my $jump_to;
    my $label;
    my $instruction;
    my $function;
    my $register;
    my $register_assign_value;
    my @enter_exit_functions;
    my $enter_exit_number = 0;
    foreach (@func_lines_min) {
        if (m~cwrap_(log|data)_~) {
            next;
        }
        elsif (m~^(\.L\d+)\:~) {
            $label = $1;
            $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: found %s:\n], Time::HiRes::time() - $ts, $label;
            $register = 'rdi';
        }
        elsif (m~^\s+movq\s+\%(r..),\s*\%rdi~) {
            $register = $1;
            $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: found \tmovq rdi <-- %s\n], Time::HiRes::time() - $ts, $register;
        }
        elsif (m~^\s+(j[^\s]+)\s+(\.L\d+)~) {
            my ($jump, $label_to) = ($1, $2);
            $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: found \t%s %s\n], Time::HiRes::time() - $ts, $jump, $label_to;
            foreach my $register (keys %{ $h->{$label}{register} }) {
                #printf qq[  - copying register %s = %s\n], $register, $h->{$label}{register}{$register};
                $jump_to->{$label_to}{register}{$register} = $h->{$label}{register}{$register};
            }
        }
        elsif (m~^\s+(leaq|movq)\s+([^\(]+)\(\%rip\), \%(r..)~) {
            ($instruction, $function, $register) = ($1, $2, $3);
            $function =~ s~\@GOTPCREL~~;
            $register_assign_value->{$register}{$function} ++;
            $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: found \t%s %s <-- &%s\n], Time::HiRes::time() - $ts, $instruction, $register, $function;
            $h->{$label}{register}{$register} = $function;
        }
        elsif (m~^\s+(call|jmp)\s+(__cyg_profile_func_(enter|exit))\@PLT~) {
            my ($call_or_jump, $enter_exit) = ($1, $2);
            my $enter_exit_name = "?";
            my $hint;
            if (exists $h->{$label}{register}{$register}) {
                $enter_exit_name = $h->{$label}{register}{$register};
                push @enter_exit_functions, $enter_exit_name;
            }
            elsif (exists $jump_to->{$label}{register}{$register}) {
                $enter_exit_name = $jump_to->{$label}{register}{$register};
                $hint = sprintf ' indirect via jump via %s and register %s', $label, $register;
                push @enter_exit_functions, $enter_exit_name;
            }
            else {
                # come here if no register found probably because label not scanned yet?
                push @enter_exit_functions, sprintf qq[label=%s register=%s], $label, $register;
            }
            $enter_exit_number ++;
            $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: found \t%s(%s) #%d%s\n], Time::HiRes::time() - $ts, $enter_exit, $enter_exit_name, $enter_exit_number, $hint;
        }
        #printf qq[%s], $_;
    } # foreach (@func_lines_min)
    #fixme printf qq[- found enter exit functions: %d\n], scalar @enter_exit_functions;
    $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: found enter exit functions: %d\n], Time::HiRes::time() - $ts, scalar @enter_exit_functions;
    my $enter_exit_number = 0;
    foreach (@enter_exit_functions) {
        my $hint;
        if (m~^label=([^ ]+) register=(.*)$~) {
            my ($label, $register) = ($1, $2);
            my @unique_register_assignments = keys %{ $register_assign_value->{$register} };
            if (1 == scalar @unique_register_assignments) {
                $_ = $unique_register_assignments[0];
                $hint = sprintf " <-- assigned because unique register %s value", $register;
            }
            elsif (exists $jump_to->{$label}{register}{$register}) {
                $_ = $jump_to->{$label}{register}{$register};
                $hint = sprintf " <-- indirect via jump via %s and register %s", $label, $register;
            }
        }
        $enter_exit_number ++;
        $log .= sprintf qq[%f     - cwrap: match_enter_exit_with_mangled_names: enter exit function: #%d %s%s%s\n], Time::HiRes::time() - $ts, $enter_exit_number, $_, m~^label=~ ? "" : "()", $hint;
        cwrap_die(sprintf qq[%f ERROR: internal: cwrap: match_enter_exit_with_mangled_names: failed to match enter exit function!\n], Time::HiRes::time() - $ts) if (m~^label=~);
    }
    return @enter_exit_functions;
} # sub match_enter_exit_with_mangled_names()

sub read_modify_rewrite_assembler_file {
    my ($s_file) = @_;

    cwrap_die(sprintf qq[%f ERROR: internal: cwrap: expected assembler file does not exist: %s\n], Time::HiRes::time() - $ts, $s_file) if (not -e $s_file);

    my $s_file_line  = `cat $s_file`;
    my @s_file_lines = split(m~\n~, $s_file_line);
    $log .= sprintf qq[%f - cwrap: assembler file: name : < %s <-- %d lines\n], Time::HiRes::time() - $ts, $s_file, scalar @s_file_lines;

    #
    # 1. search for __cyg_profile_func_(enter|exit)
    # 2. work backwards to the correct leaq <unique mangled function name> and replace with leaq cwrap_data_<unique mangled function name>
    #

    #    leaq   main(%rip), %rdi
    #    leaq   inc_a(%rip), %rbp
    # ...
    #    call   __cyg_profile_func_enter@PLT
    # ...
    #    movq   %rbp, %rdi
    #    call   __cyg_profile_func_enter@PLT <-- inline function #1 enter via rbp
    # ...
    #    movq   %rbp, %rdi
    #    call   __cyg_profile_func_exit@PLT <-- inline function #1 leave via rbp
    # ...
    #    leaq   inc_b(%rip), %rdi
    #    call   __cyg_profile_func_enter@PLT <-- inline function #2 enter
    # ...
    #    leaq   inc_b(%rip), %rdi
    #    call   __cyg_profile_func_exit@PLT <-- inline function #2 enter
    # ...
    #    leaq   main(%rip), %rdi
    #    call   __cyg_profile_func_exit@PLT

    #    movq   _ZN6binpac9ExceptionC2EPKc@GOTPCREL(%rip), %rax
    #    movq   %rax, %rdi
    #    call   __cyg_profile_func_enter@PLT

    my $debug_search = 1; # fixme

    my $h_labels_to_rewrite;
    my $h_mangled_2_demangled;
    my $h_demangled_2_mangled;

    my $t1 = Time::HiRes::time();
    my @s_file_line_index_start = indexes { m~\s+\.type\s+([^,]+),\s*\@function~ } @s_file_lines; # e.g. .type   next_entry, @function
    my $t2 = Time::HiRes::time();
    $log .= sprintf qq[%f - cwrap: assembler file: found '.type <function name>, \@function' instances: %d in %fs\n], Time::HiRes::time() - $ts, scalar @s_file_line_index_start, $t2 - $t1;

    my $t1 = Time::HiRes::time();
    my @s_file_line_index_end = indexes { m~\s+\.cfi_endproc~ } @s_file_lines; # e.g. .cfi_endproc
    my $t2 = Time::HiRes::time();
    $log .= sprintf qq[%f - cwrap: assembler file: found '.cfi_endproc' instances: %d in %fs\n], Time::HiRes::time() - $ts, scalar @s_file_line_index_end, $t2 - $t1;

    $log .= sprintf qq[%f - cwrap: assembler file: finding function name associated with each enter|exit\n], Time::HiRes::time() - $ts;
    cwrap_die(sprintf qq[%f ERROR: internal: cwrap: assembler file: found %d function starts but %d function ends!\n], Time::HiRes::time() - $ts, scalar @s_file_line_index_start, scalar @s_file_line_index_end) if (scalar(@s_file_line_index_start) != scalar(@s_file_line_index_end));

    foreach my $i (0..$#s_file_line_index_start) {
        my  $a = $s_file_line_index_start[0 + $i];
        my  $z = $s_file_line_index_end[0 + $i];
        my ($mangled_name) = $s_file_lines[$a] =~ m~\s+\.type\s+([^,]+),\s*\@function~;

        next if ($mangled_name =~ m~\.cold~); # skip this section on its own because the previous section will have 'enlarged' into this section

        my  $next_a = $s_file_line_index_start[1 + $i];
        my  $next_z = $s_file_line_index_end[1 + $i];
        my ($next_mangled_name) = $s_file_lines[$next_a] =~ m~\s+\.type\s+([^,]+),\s*\@function~;
        if ($next_mangled_name =~ m~\.cold~) {
            $log .= sprintf qq[%f   - cwrap: assembler file: line %d to %d for function %s() expanded to .cold function; line %d to %d\n], Time::HiRes::time() - $ts, $a, $z, $mangled_name, $a, $next_z if($debug_search);
            $z = $next_z; # if next section is '.cold' then merge it into this section
        }

        my $t1 = Time::HiRes::time();
        my @s_file_line_index_cyg = indexes { m~(call|jmp)\s+__cyg_profile_func_(enter|exit)~ } @s_file_lines[$a..$z]; # (call|jmp) __cyg_profile_func_exit
        my $t2 = Time::HiRes::time();

        $log .= sprintf qq[%f   - cwrap: assembler file: line %d to %d for function with %d enter|exits: %s()\n], Time::HiRes::time() - $ts, $a, $z, scalar @s_file_line_index_cyg, $mangled_name if($debug_search);

        my @enter_exit_functions;
        if (1 == scalar @s_file_line_index_cyg) {
            # come here if only 1 enter|exit calls, therefore no embedded functions to complicate things; typically this is <function name>.cold
            $mangled_name =~ s~\.cold~~;
            push @enter_exit_functions, $mangled_name;
        }
        elsif (2 == scalar @s_file_line_index_cyg) {
            # come here if only 2 enter|exit calls, therefore no embedded functions to complicate things
            push @enter_exit_functions, $mangled_name;
            push @enter_exit_functions, $mangled_name;
        }
        else {
            # come here if an odd number of enter|exit calls, therefore need to analyse names for potential embedded functions
            @enter_exit_functions = match_enter_exit_with_mangled_names($a, $z, \@s_file_lines);
        }
        cwrap_die(sprintf qq[%f ERROR: internal: cwrap: assembler file: found %d enter exit functions but %d function names!\n], Time::HiRes::time() - $ts, scalar @s_file_line_index_cyg, scalar @enter_exit_functions) if (scalar(@s_file_line_index_cyg) != scalar(@enter_exit_functions));

        foreach my $n (0..$#s_file_line_index_cyg) {
            my $p            = $s_file_line_index_cyg[$n];
            my $mangled_name = $enter_exit_functions[$n];

            my $note;
            if ($mangled_name =~ m~\.~) {
                # note: unbelievably, some labels can have dots in them, e.g.: _GLOBAL__sub_I_cpp_example_1.b.cpp <-- bug in gcc ?
                my $mangled_name_with_dot = $mangled_name;
                my $mangled_name_no___dot = $mangled_name;
                   $mangled_name_no___dot =~ s~\.~_~g;
                $h_labels_to_rewrite->{$mangled_name_with_dot} = $mangled_name_no___dot;
                $note = " (converted dots to underscores)";
            }

            if (not exists $h_mangled_2_demangled->{$mangled_name}) {
                my $demangled_name = demangle_name($mangled_name);
                $h_mangled_2_demangled->{$mangled_name  } = $demangled_name;
                $h_demangled_2_mangled->{$demangled_name} =   $mangled_name;
            }

            $s_file_lines[$a + $p] .= sprintf qq[ # <-- rdi=&%s, rsi=&cwrap_data_%s], $mangled_name, $mangled_name;

            # use edx below because call __cyg_profile_func_(enter|exit) only uses 2 parameters, RDI & RSI, therefore use 3rd parameter RDX for comparison; see https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI
            my $skip_label = sprintf qq[.L_cwrap_skip_%s_%d], "cyg_profile_func", $a + $p;
            my $original_enter_exit_call = $s_file_lines[$a + $p];
            my $optional_ret_if_jmp_enter_exit = sprintf qq[\tret\n] if ($original_enter_exit_call =~ m~jmp~);
            # todo: consider eliminating cwrap_log_verbosity and just testing cwrap_data_$mangled_name as zero or non-zero? faster?
            # non -fPIC code: movl  cwrap_data_$mangled_name(%rip), %edx
            # non -fPIC code: cmpl  cwrap_log_verbosity(%rip), %edx
            # non -fPIC code: jg    $skip_label
            $s_file_lines[$a + $p] = <<EOF;


    movq    cwrap_log_verbosity\@GOTPCREL(%rip), %rax
    movl    (%rax), %edx
    movq    cwrap_data_$mangled_name\@GOTPCREL(%rip), %rsi
    movl    (%rsi), %eax
    cmpl    %eax, %edx
    jl  $skip_label
$original_enter_exit_call
$skip_label:
$optional_ret_if_jmp_enter_exit
EOF

            $log .= sprintf qq[%f     - cwrap: assembler file: line %d: %s%s\n], Time::HiRes::time() - $ts, $a + $p, pretty_asm($original_enter_exit_call), $note if($debug_search);
        } # foreach my $p
    } # foreach my $i

if(0) {
    my $t1 = Time::HiRes::time();
    my @s_file_line_index = indexes { m~(call|jmp)\s+__cyg_profile_func_(enter|exit)~ } @s_file_lines; # (call|jmp) __cyg_profile_func_exit
    my $t2 = Time::HiRes::time();
    $log .= sprintf qq[%f - cwrap: found __cyg_profile_func_(enter|exit}() calls: %d in %fs\n], Time::HiRes::time() - $ts, scalar @s_file_line_index, $t2 - $t1;

    my $enable_munge_cyg_profile_func = 1;
    if (0) {
        $log .= sprintf qq[%f   - cwrap: NOTE: disabling munging __cyg_profile_func_(enter|exit}() calls\n], Time::HiRes::time() - $ts;
        $enable_munge_cyg_profile_func = 0;
    }

    #moved above my $h_labels_to_rewrite;
    #moved above my $h_mangled_2_demangled;
    #moved above my $h_demangled_2_mangled;
    foreach my $i (@s_file_line_index) {
        my ($type) = $s_file_lines[$i -0] =~ m~__cyg_profile_func_(enter|exit)~;
        $log .= sprintf qq[%f   - cwrap: starting at line %d: %s\n], Time::HiRes::time() - $ts, $i, pretty_asm($s_file_lines[$i -0]) if($debug_search);
        cwrap_die(sprintf qq[%f ERROR: cwrap: cannot determine enter or exit type!\n], Time::HiRes::time() - $ts) if (not defined $type);
        my $instruction;
        my $mangled_name;
        my $mangled_name_line;
        my $mangled_name_rest;
        my $label_to_find = "";
        my $considering_labels = 0;
        my $register = "\%rdi"; # rdi is Linux calling convention parameter #1; https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI
        my $lines_back = 1;
        do {
            if (($label_to_find eq "") && $s_file_lines[$i -$lines_back] =~ m~(leaq|movq)\s+cwrap_data_([_A-Za-z0-9\.]+)(.*),.*$register~) {
                $log .= sprintf qq[%f   - cwrap: found %s at %d lines back: %s <-- already instrumented!\n], Time::HiRes::time() - $ts, $register, $lines_back, pretty_asm($s_file_lines[$i -$lines_back]) if($debug_search);
                $instruction       = $1;
                $mangled_name      = $2; # e.g. leaq _ZN3FooD2Ev(%rip), %rdi
                $mangled_name_rest = $3;
                $mangled_name_line = -1;
                goto FOUND_LEAQ;
            }
            elsif (($label_to_find eq "") && $s_file_lines[$i -$lines_back] =~ m~(leaq|movq)\s+([_A-Za-z0-9\.]+)(.*),.*$register~) { # e.g. leaq    strip_components(%rip), %rdi
                $log .= sprintf qq[%f   - cwrap: found %s at %d lines back: %s <-- instrumenting\n], Time::HiRes::time() - $ts, $register, $lines_back, pretty_asm($s_file_lines[$i -$lines_back]) if($debug_search);
                $instruction       = $1;
                $mangled_name      = $2; # e.g. leaq _ZN3FooD2Ev(%rip), %rdi
                $mangled_name_rest = $3;
                $mangled_name_line = $i - $lines_back;
                goto FOUND_LEAQ;
            }
            elsif (($label_to_find eq "") && $s_file_lines[$i -$lines_back] =~ m~movq\s+(\%[_A-Za-z0-9\.]+).*,.*$register~) { # movq %rbp, %rdi
                $log .= sprintf qq[%f   - cwrap: found %s at %d lines back: %s\n], Time::HiRes::time() - $ts, $register, $lines_back, pretty_asm($s_file_lines[$i -$lines_back]) if($debug_search);
                $register = $1;
            }
            elsif (($label_to_find eq "") && $s_file_lines[$i -$lines_back] =~ m~^([^\.][_A-Za-z0-9\.]+):\s*$~) { # _Z41__static_initialization_and_destruction_0ii.cold
                $mangled_name      =  $1;
                $mangled_name      =~ s~\.cold$~~;
                $mangled_name_line = undef; # do not rewrite labels!
                $log .= sprintf qq[%f   - cwrap: found label %d lines back: %s\n], Time::HiRes::time() - $ts, $lines_back, pretty_asm($s_file_lines[$i -$lines_back]) if($debug_search);
                goto FOUND_LEAQ;
            }
            elsif ($considering_labels && ($label_to_find eq "") && $s_file_lines[$i -$lines_back] =~ m~^(\.L\d+):~) { # e.g. .L546:
                $label_to_find = $1;
                $log .= sprintf qq[%f   - cwrap: found L label %d lines back: %s\n], Time::HiRes::time() - $ts, $lines_back, pretty_asm($s_file_lines[$i -$lines_back]) if($debug_search);
            }
            elsif (($label_to_find ne "") && $s_file_lines[$i -$lines_back] =~ m~\Q$label_to_find\E~) { # e.g. .L546:
                $label_to_find = "";
                $considering_labels = 0;
                $log .= sprintf qq[%f   - cwrap: found L label %d lines back: %s\n], Time::HiRes::time() - $ts, $lines_back, pretty_asm($s_file_lines[$i -$lines_back]) if($debug_search);
            }
            elsif (($label_to_find eq "") && $s_file_lines[$i -$lines_back] =~ m~^\s*jmp\s+~) { # e.g. jmp  .L518
                $log .= sprintf qq[%f   - cwrap: found jmp %d lines back: %s\n], Time::HiRes::time() - $ts, $lines_back, pretty_asm($s_file_lines[$i -$lines_back]) if($debug_search);
                cwrap_die(sprintf qq[%f ERROR: internal: cwrap: finding a jmp means something likely went wrong searching for the enter or exit label\n], Time::HiRes::time() - $ts, 1 + $i);
            }

            $lines_back ++;
        } while ($lines_back < $i);
        cwrap_die(sprintf qq[%f ERROR: internal: cwrap: cannot find leaq/movq instruction in assembler file before line %d!\n], Time::HiRes::time() - $ts, 1 + $i);

        FOUND_LEAQ:;

        if ($mangled_name =~ m~^\d~) {
            cwrap_die(sprintf qq[%f ERROR: internal: cwrap: found leaq/movq instruction in assembler file before line %d but mangled name begins with a digit: %s()!\n], Time::HiRes::time() - $ts, 1 + $i, $mangled_name);
        }

        my $note;
        if ($mangled_name =~ m~\.~) {
            # note: unbelievably, some labels can have dots in them, e.g.: _GLOBAL__sub_I_cpp_example_1.b.cpp <-- bug in gcc ?
            my $mangled_name_with_dot = $mangled_name;
            my $mangled_name_no___dot = $mangled_name;
               $mangled_name_no___dot =~ s~\.~_~g;
            $h_labels_to_rewrite->{$mangled_name_with_dot} = $mangled_name_no___dot;
            $note = " (converted dots to underscores)";
        }

        if (not exists $h_mangled_2_demangled->{$mangled_name}) {
            my $demangled_name = demangle_name($mangled_name);
            $h_mangled_2_demangled->{$mangled_name  } = $demangled_name;
            $h_demangled_2_mangled->{$demangled_name} =   $mangled_name;
        }

        # change original leaq or movq from foo() to cwrap_data_foo()
        my $fpic;
        my $fpic_note;
        if ($mangled_name_rest !~ m~GOTPCREL~i) {
            $fpic      = '@GOTPCREL';
            $fpic_note = ' (append GOTPCREL)';
        }
        $log .= sprintf qq[%f   - cwrap: line %d: %-5s %s AKA %s demangled%s%s%s\n], Time::HiRes::time() - $ts, $i, $type, $mangled_name, $h_mangled_2_demangled->{$mangled_name}, ($mangled_name_line >= 0) ? "" : " (via $register register!)", $note, $fpic_note;
        $log .= sprintf qq[%f   - cwrap:\n], Time::HiRes::time() - $ts if($debug_search);
        if ($mangled_name_line >= 0) {
            if ($enable_munge_cyg_profile_func) {
                if    ($instruction eq 'leaq') { $s_file_lines[$mangled_name_line] =~ s~leaq(\s+)($mangled_name)~movq$1cwrap_data_$2$fpic~; }
                elsif ($instruction eq 'movq') { $s_file_lines[$mangled_name_line] =~ s~movq(\s+)($mangled_name)~movq$1cwrap_data_$2$fpic~; }
                else {
                    # come here if e.g. no leaq / movq but instead .cold label found? so do nothing...
                }
            }
        }

        # use edx below because call __cyg_profile_func_(enter|exit) only uses 2 parameters, RDI & RSI, therefore use 3rd parameter RDX for comparison; see https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI
        my $skip_label = sprintf qq[.L_cwrap_skip_%s_%d], "cyg_profile_func", $i;
        my $save_call = $s_file_lines[$i];
        # todo: consider eliminating cwrap_log_verbosity and just testing cwrap_data_$mangled_name as zero or non-zero? faster?
        # non -fPIC code: movl  cwrap_data_$mangled_name(%rip), %edx
        # non -fPIC code: cmpl  cwrap_log_verbosity(%rip), %edx
        # non -fPIC code: jg    $skip_label
        $s_file_lines[$i] = <<EOF;

    movq    cwrap_log_verbosity\@GOTPCREL(%rip), %rax
    movl    (%rax), %edx
    movq    cwrap_data_$mangled_name\@GOTPCREL(%rip), %rax
    movl    (%rax), %eax
    cmpl    %eax, %edx
    jl  $skip_label
EOF
        $s_file_lines[$i] .= sprintf qq[%s\n], $save_call; # original call to __cyg_profile_func_(enter|exit)
        $s_file_lines[$i] .= sprintf qq[%s:\n], $skip_label;
        if($save_call =~ m~jmp~) {
            $s_file_lines[$i] .= sprintf qq[\tret\n];
        }
        $s_file_lines[$i] .= sprintf qq[\n];
} # fixme
    } # foreach my $i

    #
    # 1. search for pushsection / asciz / popsection,
    # 2. determine unique unmangled function name containing if(...)
    # 3. replace movl cwrap_log_verbosity_dummy with cwrap_data_<unique mangled function name>...
    # 4. todo: delete pushsection / asciz / popsection and ascii name
    #

    # C:    .type   __PRETTY_FUNCTION__.3193, @object
    # C:    .size   __PRETTY_FUNCTION__.3193, 5
    # C:__PRETTY_FUNCTION__.3193:
    # C:    .string "main"
    # C:...
    # C:#APP
    # C:# 41 "cpp-example-1.a.cpp" 1
    # C:    .pushsection __cwrap, "S", @note; .int 9; .asciz "$__PRETTY_FUNCTION__.3193"; .popsection
    # C:
    # C:# 0 "" 2
    # C:    .loc 1 41 5 view .LVU77
    # C:#NO_APP
    # C:    movl    cwrap_log_verbosity(%rip), %eax
    # C:    cmpl    %eax, 36+cwrap_log_verbosity_dummy(%rip)
    # C:    jle .L21

    # CPP:.LC13:
    # CPP:  .string "int main()"
    # CPP:...
    # CPP:#APP
    # CPP:# 41 "cpp-example-1.a.cpp" 1
    # CPP:  .pushsection __cwrap, "S", @note; .int 9; .asciz "$.LC13"; .popsection
    # CPP:
    # CPP:# 0 "" 2
    # CPP:  .loc 1 41 5 view .LVU190
    # CPP:#NO_APP
    # CPP:  movl    cwrap_log_verbosity(%rip), %eax
    # CPP:  cmpl    %eax, 36+cwrap_log_verbosity_dummy(%rip)
    # CPP:  jle .L51

    my $t1 = Time::HiRes::time();
    my @s_file_line_index = indexes { m~pushsection __cwrap.*\.int.*\.asciz "\$([^"]+)"~ } @s_file_lines;
    my $t2 = Time::HiRes::time();
    $log .= sprintf qq[%f - cwrap: found pushsection __cwrap instances: %d in %fs\n], Time::HiRes::time() - $ts, scalar @s_file_line_index, $t2 - $t1;

    my $s_file_line  = join("\n", @s_file_lines);

    foreach my $i (@s_file_line_index) {
        my ($line, $label) = $s_file_lines[$i -0] =~ m~pushsection __cwrap.*\.int (\d+); \.asciz "\$([^"]+)"~;
        my ($pretty_function) = $s_file_line =~ m~$label\:\s+\.string\s+"([^"]+)"~s;
        $log .= sprintf qq[%f   - cwrap: pretty_function=%s\n], Time::HiRes::time() - $ts, $pretty_function if($debug_search);
        cwrap_die(sprintf qq[%f ERROR: cwrap: cannot find pretty_function via label: %s!\n], Time::HiRes::time() - $ts, $label) if (not defined $pretty_function);

        my $demangled = $pretty_function;
        if ($demangled =~ m~ \[with ([^\s]+)\s*=\s*(.*)]~) { # e.g. my_type get_max(my_type, my_type) [with my_type = int]
            # come here to make this                           e.g.     int get_max<int>(int, int)
            my ($my_var, $my_type) = ($1, $2);
            $log .= sprintf qq[%f   - cwrap: converting assembler to pretty function demangled function: %s\n], Time::HiRes::time() - $ts, $demangled if (not exists $h_demangled_2_mangled->{$demangled});
            $demangled =~ s~$my_var~$my_type~g;
            $demangled =~ s~\(~<$my_type>(~;
            $demangled =~ s~ \[with .*~~; # stip [with ...] part
        }
        else {
            while ($demangled =~ s~^[^\s\(]+\s+~~) {} # strip return type from e.g. unsigned char * my_func()
        }
        $log .= sprintf qq[%f   - cwrap: demangled=%s\n], Time::HiRes::time() - $ts, $demangled if($debug_search);
        $demangled = demangle_name_sanitize_type_order($demangled);
        $log .= sprintf qq[%f   - cwrap: demangled=%s <-- after type sanitization\n], Time::HiRes::time() - $ts, $demangled if($debug_search);
        if (not exists $h_demangled_2_mangled->{$demangled}) {
            $log .= sprintf qq[%f   - cwrap: removing parameters (...) because cannot find demangled function: %s\n], Time::HiRes::time() - $ts, $demangled;
            $demangled =~ s~\(.*$~~; # strip (<params>) from e.g. int main()
        }
        if (not exists $h_demangled_2_mangled->{$demangled}) {
            foreach my $demangled_key (sort keys %{$h_demangled_2_mangled}) {
                $log .= sprintf qq[%f   - cwrap: non-matching demangled key: %d bytes: %s\n], Time::HiRes::time() - $ts, length($demangled_key), $demangled_key;
            }
            cwrap_die(sprintf qq[%f ERROR: cwrap: cannot find mangled function via demangled function: %s // via pretty function %s\n], Time::HiRes::time() - $ts, $demangled, $pretty_function);
        }
        my $mangled = $h_demangled_2_mangled->{$demangled};

        $log .= sprintf qq[%f   - cwrap: starting at line %d: %s; line=%d label=%s pretty_function=%s AKA %s mangled\n], Time::HiRes::time() - $ts, $i, pretty_asm($s_file_lines[$i -0]), $line, $label, $pretty_function, $mangled if($debug_search);

        my $unique_dummy = sprintf qq[cwrap_data_verbosity_dummy_%u], $line;
        if ($s_file_line =~ s~$unique_dummy~cwrap_data_$mangled~) {
            # e.g. movq cwrap_data_verbosity_dummy_8@GOTPCREL(%rip), %rax
        }
        else {
            cwrap_die(sprintf qq[%f ERROR: internal: cwrap: cannot find %s in assembler file referenced by line %d!\n], Time::HiRes::time() - $ts, $unique_dummy, $i);
        }
    } # foreach my $i

    #
    # re-write any labels with dots!
    #

    if (scalar keys %{$h_labels_to_rewrite} > 0) {
        $log .= sprintf qq[%f - cwrap: rewriting %d dodgy dot labels\n], Time::HiRes::time() - $ts, scalar keys %{$h_labels_to_rewrite};
        foreach my $mangled_name_with_dot (keys %{$h_labels_to_rewrite}) {
            my $mangled_name = $h_labels_to_rewrite->{$mangled_name_with_dot};
            $log .= sprintf qq[%f   - cwrap: rewriting dodgy dot label %s to %s\n], Time::HiRes::time() - $ts, $mangled_name_with_dot, $mangled_name;
            $s_file_line =~ s~$mangled_name_with_dot~$mangled_name~gs;
        }
    }

    $s_file_line =~ s~\.string\s+"cwrap_data_verbosity_dummy_\d+"~~gm; # .string "cwrap_data_verbosity_dummy_10"

    if ($s_file_line =~ m~(cwrap_data_verbosity_dummy_\d+)~s) {
        cwrap_die(sprintf qq[%f ERROR: internal: cwrap: detected at least one unsubstituted temporary label: %s!\n], Time::HiRes::time() - $ts, $1);
    }

    #
    # write out modified assembler file
    #

    my $s_file_out = sprintf qq[%s.2.s], $s_file;
    $log .= sprintf qq[%f - cwrap: assembler file: name : > %s\n], Time::HiRes::time() - $ts, $s_file_out;
    open(my $out, '>', $s_file_out) || cwrap_die(sprintf qq[%f ERROR: cwrap cannot open file for writing: %s; $1\n], Time::HiRes::time() - $ts, $s_file_out);
    $s_file_line .= "\n";
    syswrite($out, $s_file_line, length($s_file_line));
    close $out;
} # read_modify_rewrite_assembler_file()

sub using_undefind_error_write_cwrap_c {
    my ($output, $output_type) = @_; # output lines from nm or gxx command

    my @output = split(m~\n~, $output);
    $log .= sprintf qq[%f - cwrap: examining lines of %s output: %d\n], Time::HiRes::time() - $ts, $output_type, scalar @output;
    if (0) { foreach my $line (@output) { $log .= sprintf qq[%f - cwrap: debug output: %s\n], Time::HiRes::time() - $ts, $line; } }

    my $h;
    if ($output_type eq 'nm') {
        # come here to process output with undefineds from nm
        foreach my $undefined (@output) {
            chomp $undefined; # e.g. ../aux/paraglob/src/ahocorasick/libahocorasick.a:AhoCorasickPlus.cpp.o:                 U cwrap_data__ZNK9__gnu_cxx13new_allocatorIiE8max_sizeEv
            next if ($undefined =~ m~cwrap_log_~); # do not generate cwrap_data structs for cwrap_log_*() functions
            if ($undefined =~ m~^(.+?):\s+U\s+(.*)~) {
                my ($file, $undefined_cwrap_data) = ($1, $2);
                $h->{$undefined_cwrap_data} = $file if (not exists $h->{$undefined_cwrap_data});
            }
            else {
                cwrap_die(sprintf qq[%f ERROR: internal: cwrap: do not understand nm output line: %s\n], Time::HiRes::time() - $ts, $undefined);
            }
        }
    }
    else {
        # come here to process output with undefineds from gxx
        my @undefined_errors = grep(m~undefined reference to .cwrap_data_~, @output); # e.g. cpp-example-1.cpp:5: undefined reference to `cwrap__Z8clean_upPi'

        # first grab all the undefined error; note: gcc appears to spit them out in a random order!
        foreach my $undefined_error (@undefined_errors) { # e.g. /usr/bin/ld: testCXXCompiler.cxx:(.text+0x1d): undefined reference to `cwrap_data_main'
            next if ($undefined_error =~ m~cwrap_log_~);
            chomp $undefined_error;
            my ($source_file, $source_line, $missing_ref) = $undefined_error =~ m~([^/]+):([^\:]+): undefined reference to .(cwrap_[_A-Za-z0-9]+)~;
            $h->{$missing_ref} = $source_file if (not exists $h->{$missing_ref});
        }
    }
    $log .= sprintf qq[%f - cwrap: unique undefined cwrap_data_* symbols in nm output: %d\n], Time::HiRes::time() - $ts, scalar keys %{$h};

    my @demangled_names; # e.g. int get_max<int>(int, int)
    my @mangled_names; # e.g. _Z7get_maxIiET_S0_S0_
    my @source_files;
    foreach my $missing_ref (sort keys %{ $h }) { # sort because always want names in same order for test scripts
        my  $source_file = $h->{$missing_ref};
        my ($mangled_name) = $missing_ref =~ m~cwrap_data_(.*)~;
        push @source_files, $source_file;
        push @mangled_names, $mangled_name; # e.g. _Z7get_maxIiET_S0_S0_
        my $demangled_name = demangle_name($mangled_name);
        push @demangled_names, $demangled_name; # e.g. int get_max<int>(int, int)
    }
    #todo: consider sorting the function names by demangled name instead of mangled name!

    $log .= sprintf qq[%f - cwrap: writing %d missing cwrap structs to: %s\n], Time::HiRes::time() - $ts, scalar keys %{ $h }, $cwrap_c;
    cwrap_die(sprintf qq[%f ERROR: internal: cwrap: zero cwrap structs; should never be zero\n], Time::HiRes::time() - $ts) if (0 == scalar keys %{ $h });
    open(my $out, '>', $cwrap_c) || cwrap_die(sprintf qq[%f ERROR: cwrap: cannot open file for writing: %s\n], Time::HiRes::time() - $ts, $cwrap_c);
    printf $out <<EOF;
#ifndef _GNU_SOURCE
#define _GNU_SOURCE      /* See feature_test_macros(7) */
#endif
#include <unistd.h>
#include <sys/syscall.h> /* for syscall(), SYS_gettid */
#include <signal.h>      /* for raise() */
#include <stdlib.h>      /* for exit() */
#include <string.h>      /* for memcmp() */
#include <stdio.h>
#include <stdarg.h>
#include <sys/time.h>
#include <locale.h>
#define UNW_LOCAL_ONLY
#include <libunwind.h>

#ifdef COR_XXHASH_STACK
#define XXH_INLINE_ALL
#define XXH_STATIC_LINKING_ONLY
#include "xxhash.h"
#endif

#ifdef __cplusplus
extern  "C" {
#endif

__attribute__ ((no_instrument_function)) void __cyg_profile_func_enter(void *func, void *callsite);
__attribute__ ((no_instrument_function)) void __cyg_profile_func_exit (void *func, void *callsite);

#define CWRAP_MAGIC (0x12345678)

typedef struct CWRAP_DATA CWRAP_DATA;

struct CWRAP_DATA {
    int          verbosity; // must be 1st structure member!
    int          magic;
    int          calls;
    int          variation_x;
    int          of_y_variations;
    int          bytes___mangled_name;
    int          bytes_demangled_name;
    const char * name; int len_name; // generic demangled name
    const char * file; int len_file;
    void       * func_addr;
    CWRAP_DATA * next;
} __attribute__((packed));

#define CWRAP_LOG_LINE_MAX (256)

#ifndef CWRAP_LOG_NUM
#define CWRAP_LOG_NUM (0)
#endif

#ifndef CWRAP_LOG_CURT
#define CWRAP_LOG_CURT (0)
#endif

#ifndef CWRAP_LOG_FILE
#define CWRAP_LOG_FILE (0)
#endif

#ifndef CWRAP_LOG_COR_ID
#define CWRAP_LOG_COR_ID (1)
#endif

#ifndef CWRAP_LOG_UNWIND
#define CWRAP_LOG_UNWIND (0)
#endif

#ifndef CWRAP_LOG_THREAD_ID
#define CWRAP_LOG_THREAD_ID (0)
#endif

#ifndef CWRAP_LOG_STACK_PTR
#define CWRAP_LOG_STACK_PTR (0)
#endif

#ifndef CWRAP_LOG_TIMESTAMP
#define CWRAP_LOG_TIMESTAMP (0)
#endif

#ifndef CWRAP_LOG_ON_VALGRIND
#define CWRAP_LOG_ON_VALGRIND (0)
#endif

#define COR_ID_MAX (1000)

typedef struct CWRAP_LOG_COR {
    void * unique; // unique value representing last log line
    int    indent;
    int    line_result_pos;
    int    line_append_pos;
    int    line_pos;
    char   line_result[CWRAP_LOG_LINE_MAX];
    char   line_append[CWRAP_LOG_LINE_MAX];
    char   line[CWRAP_LOG_LINE_MAX];
} __attribute__((packed)) CWRAP_LOG_COR;

       __thread int           cor_id                         = 0;
       __thread char        * cor_stack_addr_main            = NULL   ; // stack base for main thread
       __thread char        * cor_stack_addr_help            = NULL   ; // stack base for help thread
       __thread int           cor_stack_size_main            = 0      ; // stack size for main thread
       __thread int           cor_stack_size_help            = 0      ; // stack size for help thread

       __thread CWRAP_LOG_COR cwrap_log_cor[COR_ID_MAX]      = {0}; // todo: make this dynamically grow to the necessary size; mremap() ? //fixme indentation
                char          cwrap_log_spaces[]             = "                                                                                                                                                                                                ";
                int           cwrap_log_spaces_len           = sizeof(cwrap_log_spaces);
                int           cwrap_log_verbosity            = 1;
                void        * cwrap_log_quiet_until_cw       = NULL;
static          FILE        * cwrap_log_file                 = NULL;
static          int           cwrap_log_fd;
static          double        cwrap_log_time                 = 0             ; // very first timestamp
static          int           cwrap_log_output_num           = CWRAP_LOG_NUM ; // increment and output a number of every output
static          int           cwrap_log_output_curt          = CWRAP_LOG_CURT; // try to fold enter and leave lines if possible
static          int           cwrap_log_output_file          = CWRAP_LOG_FILE; // output to file or stdout?
static          int           cwrap_log_output_cor_id        = CWRAP_LOG_COR_ID;
static          int           cwrap_log_output_unwind        = CWRAP_LOG_UNWIND;
static          int           cwrap_log_output_thread_id     = CWRAP_LOG_THREAD_ID;
static          int           cwrap_log_output_stack_pointer = CWRAP_LOG_STACK_PTR;
static          int           cwrap_log_output_elapsed_time  = CWRAP_LOG_TIMESTAMP;
                int           cwrap_log_output_on_valgrind   = CWRAP_LOG_ON_VALGRIND;

extern void cwrap_log_push(int indent_direction, int no_append, int is_inside, int not_plain, const char * format, ...);

double cwrap_get_time_in_seconds(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + 1.e-6 * (double)tv.tv_usec;
}

const char * cwrap_log_append_get(void)
{
    const char * result = NULL;
    if (cwrap_log_cor[cor_id].line_append_pos) {
        cwrap_log_cor[cor_id].line_append_pos = 0;
        result = &cwrap_log_cor[cor_id].line_append[0];
    }
    return result;
}

const char * cwrap_log_result_get(void)
{
    const char * result = NULL;
    if (cwrap_log_cor[cor_id].line_result_pos) {
        cwrap_log_cor[cor_id].line_result_pos = 0;
        result = &cwrap_log_cor[cor_id].line_result[0];
    }
    return result;
}

// todo: performance optimization: consider refactoring this code so that all sprintf() ingredients are queued and actual sprintf()s are executed in a separate thread?

void cwrap_log_flush(void)
{
    if (cwrap_log_output_file) {
        fprintf(cwrap_log_file, "%%s\\n", &cwrap_log_cor[cor_id].line[0]);
        fflush(cwrap_log_file);
        //fsync(cwrap_log_fd); // todo: fsync intermittantly?
    }
    else {
        int pos = cwrap_log_cor[cor_id].line_pos - 1;
        if ('\\n' == cwrap_log_cor[cor_id].line[pos]) { printf("%%s"   , &cwrap_log_cor[cor_id].line[0]); }
        else                                          { printf("%%s\\n", &cwrap_log_cor[cor_id].line[0]); }
        //fflush(stdout);
    }

    cwrap_log_cor[cor_id].line_pos = 0;
}

void cwrap_log_push_v(int indent_direction, int no_append, int is_inside, int not_plain, const char * format, va_list argument_list)
{
    double time = cwrap_get_time_in_seconds();

    if (no_append && (cwrap_log_cor[cor_id].line_pos > 0)) { // todo: create & check cor_id_last too?
        const char * append = cwrap_log_append_get();
        if (cwrap_log_output_curt) {
            if (append) { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, ") { // %%s", append); } }
            else        { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, ") {"               ); } }
        }
        cwrap_log_flush();
    }

    if (no_append && (cwrap_log_cor[cor_id].line_result_pos > 0) && (indent_direction >= 0)) {
        const char * result = cwrap_log_result_get();
        cwrap_log_push(0 /* no indent_direction */, 1 /* no append */, 1 /* is inside */, 1 /* not plain */, "return %%s", result);
        cwrap_log_flush();
    }

    if (cwrap_log_output_file && (NULL == cwrap_log_file)) { // todo: make thread safe
        cwrap_log_file = fopen("cwrap.out","w+");
        cwrap_log_fd   = fileno(cwrap_log_file);
    }

    if (0 == cwrap_log_time) {
        cwrap_log_time = time;
    }

    double time_elapsed = time - cwrap_log_time;

    int stack_offset = 0;
    if (cwrap_log_output_stack_pointer) {
        char * stack_addr_to_use = cor_id ? cor_stack_addr_help : cor_stack_addr_main; // use helper thread stack address if cor_id >= 1 else use main thread stack address
        void * cwrap_log_sp      = alloca(1);
               stack_offset      = stack_addr_to_use ? (char *)cwrap_log_sp - stack_addr_to_use : 0; // only calculate stack offset if stack addr known
    }

    int indent_use = ((2 * cwrap_log_cor[cor_id].indent) < cwrap_log_spaces_len) ? (2 * cwrap_log_cor[cor_id].indent) : cwrap_log_spaces_len;
        indent_use = (indent_use < 0) ? 0 : indent_use;

    if (no_append && not_plain) {
    if (cwrap_log_output_num          ) { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "#%%d "      , cwrap_log_output_num ++         ); } }
    if (cwrap_log_output_thread_id    ) { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "T%%05ld "   , syscall(SYS_gettid)             ); } } // linux; cat /proc/sys/kernel/pid_max
    if (cwrap_log_output_cor_id       ) { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "C%%d "      , cor_id                          ); } }
    if (cwrap_log_output_stack_pointer) {
    if (stack_offset                  ) { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "SP%%d%%+8d ", cor_id ? 1 : 0, stack_offset    ); } }
    else                                { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "SP%%d%%8s " , cor_id ? 1 : 0, "+/-?"          ); } } }
    if (cwrap_log_output_elapsed_time ) { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "%%fs "      , time_elapsed                    ); } }
                                          if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "%%.*s"      , indent_use, &cwrap_log_spaces[0]); }   // note: %% because of Perl
    if (is_inside                     ) { if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos +=  snprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, "- "                                           ); } }
    } // if (no_append)
                                          if (cwrap_log_cor[cor_id].line_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_pos += vsnprintf(&cwrap_log_cor[cor_id].line[cwrap_log_cor[cor_id].line_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_pos, format       , argument_list                   ); }

    int pos = cwrap_log_cor[cor_id].line_pos - 1;
    if ('\\n' == cwrap_log_cor[cor_id].line[pos]) { cwrap_log_cor[cor_id].line[pos] = 0; cwrap_log_cor[cor_id].line_pos --; } // chomp trailing \\n if present

    cwrap_log_cor[cor_id].indent += indent_direction;
}

void cwrap_log_push(int indent_direction, int no_append, int is_inside, int not_plain, const char * format, ...)
{
    va_list argument_list;
    va_start(argument_list, format);

    cwrap_log_push_v(indent_direction, no_append, is_inside, not_plain, format, argument_list);

    va_end(argument_list);
}

void cwrap_log_pop(int indent_direction, int no_append, int is_inside, int not_plain, const char * format, ...)
{
    va_list argument_list;
    va_start(argument_list, format);

    cwrap_log_push_v(indent_direction, no_append, is_inside, not_plain, format, argument_list);
    cwrap_log_flush();

    va_end(argument_list);
}

void cwrap_log(const char * format, ...)
{
    va_list argument_list;
    va_start(argument_list, format);

    cwrap_log_cor[cor_id].unique = 0; // signal previous enters that leave folding should not occur
    cwrap_log_push_v(0 /* no indent_direction */, 1 /* no append */, 1 /* is inside */, 1 /* not plain */, format, argument_list);
    cwrap_log_flush();

    va_end(argument_list);
}

void cwrap_log_plain(const char * format, ...)
{
    va_list argument_list;
    va_start(argument_list, format);

    cwrap_log_cor[cor_id].unique = 0; // signal previous enters that leave folding should not occur
    cwrap_log_push_v(0 /* no indent_direction */, 1 /* no append */, 0 /* is inside */, 0 /* is plain */, format, argument_list);
    cwrap_log_flush();

    va_end(argument_list);
}

void cwrap_log_append(const char * format, ...)
{
    va_list argument_list;
    va_start(argument_list, format);

    if (cwrap_log_output_curt && (cwrap_log_cor[cor_id].line_pos > 0)) {
        if (cwrap_log_cor[cor_id].line_append_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_append_pos += vsnprintf(&cwrap_log_cor[cor_id].line_append[cwrap_log_cor[cor_id].line_append_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_append_pos, format, argument_list); }
    }
    else {
        cwrap_log_cor[cor_id].unique = 0; // signal previous enters that leave folding should not occur
        cwrap_log_push_v(0 /* no indent_direction */, 1 /* no append */, 1 /* is inside */, 1 /* not plain */, format, argument_list);
        cwrap_log_flush();
    }

    va_end(argument_list);
}

void cwrap_log_result(const char * format, ...)
{
    va_list argument_list;
    va_start(argument_list, format);

    if (cwrap_log_output_curt) {
        if (cwrap_log_cor[cor_id].line_result_pos < CWRAP_LOG_LINE_MAX) { cwrap_log_cor[cor_id].line_result_pos += vsnprintf(&cwrap_log_cor[cor_id].line_result[cwrap_log_cor[cor_id].line_result_pos], CWRAP_LOG_LINE_MAX - cwrap_log_cor[cor_id].line_result_pos, format, argument_list); }
        int pos = cwrap_log_cor[cor_id].line_result_pos - 1;
        if ('\\n' == cwrap_log_cor[cor_id].line_result[pos]) { cwrap_log_cor[cor_id].line_result[pos] = 0; cwrap_log_cor[cor_id].line_result_pos --; } // chomp trailing \\n if present
    }
    else {
        cwrap_log_cor[cor_id].unique = 0; // signal previous enters that leave folding should not occur
        cwrap_log_push  (0 /* no indent_direction */, 1 /* no append */, 1 /* is inside */, 1 /* not plain */, "return ");
        cwrap_log_push_v(0 /* no indent_direction */, 0 /*    append */, 1 /* is inside */, 1 /* not plain */, format, argument_list);
        cwrap_log_flush();
    }

    va_end(argument_list);
}

void cwrap_log_params(const char * format, ...)
{
    va_list argument_list;
    va_start(argument_list, format);

    if (cwrap_log_output_curt && (cwrap_log_cor[cor_id].line_pos > 0)) {
        cwrap_log_push_v(0 /* no indent_direction */, 0 /* append */, 0 /* is not inside */, 1 /* not plain */, format, argument_list);
    }
    else {
        cwrap_log_cor[cor_id].unique = 0; // signal previous enters that leave folding should not occur
        cwrap_log_push_v(0 /* no indent_direction */, 1 /* no append */, 1 /* is inside */, 1 /* not plain */, format, argument_list);
        cwrap_log_flush();
    }

    va_end(argument_list);
}

EOF

    push    @source_files, $cwrap_c;
    push   @mangled_names, "cwrap_log_quiet_until";
    push @demangled_names, "cwrap_log_quiet_until";

    push    @source_files, $cwrap_c;
    push   @mangled_names, "cwrap_log_verbosity_set";
    push @demangled_names, "cwrap_log_verbosity_set";

    push    @source_files, $cwrap_c;
    push   @mangled_names, "cwrap_log_stats";
    push @demangled_names, "cwrap_log_stats";

    push    @source_files, $cwrap_c;
    push   @mangled_names, "cwrap_log_show";
    push @demangled_names, "cwrap_log_show";

    my $default_function_verbosity = 9;
    my $mangled_name_last = "NULL";
    my $h_variation_x;
    my $h_of_y_variations;
    my $number___mangled_names = 0;
    my $number_demangled_names = 0;
    my $number___generic_names = 0;
    my  $bytes___mangled_names = 0;
    my  $bytes_demangled_names = 0;
    my  $bytes___generic_names = 0;
    foreach my $i (0..$#mangled_names) {
        my   $mangled_name =   $mangled_names[$i]; $number___mangled_names ++; $bytes___mangled_names += length(  $mangled_name);
        my $demangled_name = $demangled_names[$i]; $number_demangled_names ++; $bytes_demangled_names += length($demangled_name);
        chomp $demangled_name;
        my $compressed_demangled_name = compress_demangled_name($demangled_name);
        if (not exists $h_of_y_variations->{$compressed_demangled_name}) {
            $number___generic_names ++;
             $bytes___generic_names += length($compressed_demangled_name);
        }
        $h_of_y_variations->{$compressed_demangled_name} ++;
        $h_variation_x->{$mangled_name} = $h_of_y_variations->{$compressed_demangled_name};
    }
    $log .= sprintf qq[%f   - cwrap: number___mangled_names=%d\n], Time::HiRes::time() - $ts, $number___mangled_names;
    $log .= sprintf qq[%f   - cwrap: number_demangled_names=%d\n], Time::HiRes::time() - $ts, $number_demangled_names;
    $log .= sprintf qq[%f   - cwrap: number___generic_names=%d\n], Time::HiRes::time() - $ts, $number___generic_names;
    $log .= sprintf qq[%f   - cwrap:  bytes___mangled_names=%d\n], Time::HiRes::time() - $ts,  $bytes___mangled_names;
    $log .= sprintf qq[%f   - cwrap:  bytes_demangled_names=%d\n], Time::HiRes::time() - $ts,  $bytes_demangled_names;
    $log .= sprintf qq[%f   - cwrap:  bytes___generic_names=%d\n], Time::HiRes::time() - $ts,  $bytes___generic_names;
    foreach my $i (0..$#mangled_names) {
        my   $mangled_name =   $mangled_names[$i];
        my $demangled_name = $demangled_names[$i];
        chomp $demangled_name;
        my $compressed_demangled_name = compress_demangled_name($demangled_name);
        $log .= sprintf qq[%f   - cwrap: %-48s -> variation %d of %d for %s()\n], Time::HiRes::time() - $ts, $mangled_name, $h_variation_x->{$mangled_name}, $h_of_y_variations->{$compressed_demangled_name}, $compressed_demangled_name;
        #for non-debug source_line might look like "(.text+0x1d)": cwrap_die(sprintf qq[%f ERROR: internal: cwrap: 0 == source_line from linker undefined error: %s\n], Time::HiRes::time() - $ts, $undefineds[$i]) if (0 == $source_line);
        printf $out qq[CWRAP_DATA cwrap_data_%s = {%d, CWRAP_MAGIC, 0, %d, %d, %d, %d, "%s", %d, "%s", %d, NULL, %s};\n],
            $mangled_name,
            $default_function_verbosity,
            $h_variation_x->{$mangled_name},
            $h_of_y_variations->{$compressed_demangled_name},
            length(  $mangled_name),
            length($demangled_name),
            $compressed_demangled_name, length($compressed_demangled_name),
            $source_files[$i]         , length($source_files[$i]         ),
            $mangled_name_last;
        $mangled_name_last = sprintf qq[&cwrap_data_%s], $mangled_name;
    }

    printf $out <<EOF;

int cwrap_default_function_verbosity = $default_function_verbosity;

CWRAP_DATA * cwrap_data_start = $mangled_name_last;

#define CWRAP_FUNCTION_NAME_SIZE_MAX (256)

__thread char cwrap_log_dump_hex_buffer[256];
char          cwrap_function_name___do_global_ctors_aux[CWRAP_FUNCTION_NAME_SIZE_MAX];
char          cwrap_function_name_main                 [CWRAP_FUNCTION_NAME_SIZE_MAX];
char          cwrap_function_name_start                [CWRAP_FUNCTION_NAME_SIZE_MAX];
int           cwrap_function_names_found                = 0;
unw_word_t    cwrap_function_addr___do_global_ctors_aux = 0;
unw_word_t    cwrap_function_addr_main                  = 0;
unw_word_t    cwrap_function_addr_start                 = 0;

// fixme: todo: dump only string, only hex, or mixed
// fixme: todo: change to output index
// fixme: todo: add asserts
// fixme: todo: add multiple dests
char * cwrap_log_dump_hex(const void * pointer, int len, int len_max) { // show max len_max bytes of len bytes @ pointer
    const char * data = (const char *) pointer;
    int truncated  = len_max < len ? 2   : 0      ;
    int len_to_use = len < len_max ? len : len_max;
    cwrap_log_dump_hex_buffer[0] = '"';
    for (int x = 0; x < len_to_use; x++) {
        cwrap_log_dump_hex_buffer[1 + x] = ((data[x] < 32) || (data[x] > 127)) ? '.' : data[x];
    }
    if (truncated) {
		cwrap_log_dump_hex_buffer[1 + len_to_use + 0] = '.';
		cwrap_log_dump_hex_buffer[1 + len_to_use + 1] = '.';
	}
    cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 0] = '"';
    cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 1] = '=';
    cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 2] = '0';
    cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 3] = 'x';
    for (int x = 0; x < len_to_use; x++) {
        sprintf(&cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 4 + (x * 2)], "%%02x", data[x]);
    }
    if (truncated) {
		cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 4 + (len_to_use * 2) + 0] = '.';
		cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 4 + (len_to_use * 2) + 1] = '.';
	}
    cwrap_log_dump_hex_buffer[1 + len_to_use + truncated + 4 + (len_to_use * 2) + 2] = 0;
    return cwrap_log_dump_hex_buffer;
}

void cwrap_sanity_check_stack() {
    unw_cursor_t    cursor;
    unw_context_t   context;
    unw_word_t      ip, sp, off;
    unw_proc_info_t pip;
    char            symbol[CWRAP_FUNCTION_NAME_SIZE_MAX] = {"<unknown>"};

    unw_getcontext(&context);
    unw_init_local(&cursor, &context);

    //debug int n           = 0;
    int deep_enough = 0;
    while (unw_step(&cursor)) {
        unw_get_reg(&cursor, UNW_REG_IP, &ip);
        unw_get_reg(&cursor, UNW_REG_SP, &sp);

        unw_get_proc_info(&cursor, &pip);

        if (cwrap_function_names_found >= 3) {
            //debug char * name        = "?";

            if      (pip.start_ip == cwrap_function_addr___do_global_ctors_aux) { /* name = cwrap_function_name___do_global_ctors_aux; */ deep_enough = 1; }
            else if (pip.start_ip == cwrap_function_addr_main                 ) { /* name = cwrap_function_name_main                 ; */ deep_enough = 1; }
            else if (pip.start_ip == cwrap_function_addr_start                ) { /* name = cwrap_function_name_start                ; */ deep_enough = 1; }

            //debug printf("#%%-2d 0x%%016lx sp=0x%%016lx func=0x%%016lx AKA %%s()\\n", ++n, ip, sp, pip.start_ip, name);

            if (deep_enough)
                break;
        }
        else {
            unw_get_proc_name(&cursor, symbol, sizeof(symbol), &off);

            //debug printf("#%%-2d 0x%%016lx sp=0x%%016lx func=0x%%016lx AKA %%s() + 0x%%lx\\n", ++n, ip, sp, pip.start_ip, symbol, off);

            if ((0 == cwrap_function_addr___do_global_ctors_aux) && (0 == strcmp(symbol, "__do_global_ctors_aux"))) { cwrap_function_addr___do_global_ctors_aux = pip.start_ip; strcpy(cwrap_function_name___do_global_ctors_aux, symbol); cwrap_function_names_found ++; }
            if ((0 == cwrap_function_addr_main                 ) && (0 == strcmp(symbol, "main"                 ))) { cwrap_function_addr_main                  = pip.start_ip; strcpy(cwrap_function_name_main                 , symbol); cwrap_function_names_found ++; }
            if ((0 == cwrap_function_addr_start                ) && (0 == strcmp(symbol, "start"                ))) { cwrap_function_addr_start                 = pip.start_ip; strcpy(cwrap_function_name_start                , symbol); cwrap_function_names_found ++; }

            if (cwrap_function_names_found >= 3) {
                cwrap_log("cwrap_sanity_check_stack() discovered the addresses of functions main() and start()\\n");
            }

            deep_enough = 1;
        }
    } /* while (unw_step(&cursor)) */
    if (0 == deep_enough) { // todo: how to use CWRAP_ASSERT_INTERNAL() here? make CWRAP_ASSERT_INTERNAL() independent from other cwrap_() functions so that it can be used here?
        printf("%%05u:%%s: ERROR: assertion: ", __LINE__, __FILE__);
        printf("Used libunwind to traverse stack but no main() or start() function found; stack is corrupted?\\n");
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
} /* cwrap_sanity_check_stack() */

void cwrap_log_show(void * func_addr) { // NULL means show all functions
    int indent_save = cwrap_log_cor[cor_id].indent;
    cwrap_log_cor[cor_id].indent = 0; // flatten any indent in case deep in the stack causing snprintf issues
    __cyg_profile_func_enter(NULL, &cwrap_data_cwrap_log_show);
    cwrap_log_params("func_addr=%%p", func_addr);
    int k = 0;
    CWRAP_DATA * cwd = cwrap_data_start;
    do {
        k ++;
        if (func_addr && (func_addr != cwd->func_addr)) {
            // skip display of this function
        }
        else {
            cwrap_log("#%%'d: verbosity %%d for %%'d of %%'d function variation(s) for %%s() from %%s\\n", k, cwd->verbosity, cwd->variation_x, cwd->of_y_variations, &cwd->name[0], &cwd->file[0]);
        }
        cwd = cwd->next;
    } while (cwd);
    __cyg_profile_func_exit(NULL, &cwrap_data_cwrap_log_show);
    cwrap_log_cor[cor_id].indent = indent_save;
}

void cwrap_data_sanity_check(void * func_addr, CWRAP_DATA * cw) {
    if (cw->magic != CWRAP_MAGIC) {
        printf("ERROR: internal: cwrap bad magic; expected 0x%%x, got 0x%%x exiting // cw=%%p sizeof(CWRAP_DATA)=%%ld\\n", CWRAP_MAGIC, cw->magic, (void *)cw, sizeof(CWRAP_DATA));
        fflush(stdout);
        raise(SIGINT);
        exit(1);
    }
#if 0
    note: unfortunately this code will only work if func_addr is unique which is not necessarily true; see linker -Wl,--whole-archive option
    if (func_addr) {
        if (NULL == cw->func_addr) {
            cw->func_addr = func_addr;
        }
        else if (func_addr != cw->func_addr) {
            if (0 != strcmp(cw->name, "__static_initialization_and_destruction_0")) { // there are multiple functions named this function, so func_addr will be different!
                cwrap_log_show(    func_addr);
                cwrap_log_show(cw->func_addr);
                printf("ERROR: internal: cwrap data func_addr mismatch; expected %%p, got %%p exiting; bad assembler munging for function %%s() called previously %%d times // cw=%%p sizeof(CWRAP_DATA)=%%ld\\n", cw->func_addr, func_addr, cw->name, cw->calls, (void *)cw, sizeof(CWRAP_DATA));
                fflush(stdout);
                raise(SIGINT);
                exit(1);
            }
        }
    }
#endif
}

#define CWRAP_UNUSED_PARAMETER(param) (void)(param)

void __cyg_profile_func_enter_always(void *this_fn, void *call_site) {
    void       * fa =                this_fn  ; // function address not necessarily unique; see linker -Wl,--whole-archive option
    CWRAP_DATA * cw = (CWRAP_DATA *) call_site; // cwrap data
    cwrap_data_sanity_check(fa, cw);
    //debug printf("debug: cwrap_log_verbosity=%%d ->name=%%s\\n", cwrap_log_verbosity, cw->name);
    cwrap_log_cor[cor_id].unique = cw;
    cw->calls ++;
    if (cw->calls <= 10000) {
        if (cwrap_log_output_curt) {
            cwrap_log_push(1, 1 /* no append */, 0 /* outside */, 1 /* not plain */, "+ %%s(", cw->name);
            cwrap_log_append("#%%d ", cw->calls);
        }
        else {
            cwrap_log_push(1, 1 /* no append */, 0 /* outside */, 1 /* not plain */, "+ %%s() { #%%d", cw->name, cw->calls);
        }
    }
}

void __cyg_profile_func_enter(void *this_fn, void *call_site) {
    void       * fa =                this_fn  ; // function address not necessarily unique; see linker -Wl,--whole-archive option
    CWRAP_DATA * cw = (CWRAP_DATA *) call_site; // cwrap data
    cwrap_data_sanity_check(fa, cw);
    //debug printf("debug: cwrap_log_verbosity=%%d ->name=%%s\\n", cwrap_log_verbosity, cw->name);
    cwrap_log_cor[cor_id].unique = cw;
    if (cwrap_log_quiet_until_cw && (cwrap_log_quiet_until_cw == cw)) {
        cwrap_log_quiet_until_cw = NULL;
    }
    if (cwrap_log_quiet_until_cw == NULL) {
        __cyg_profile_func_enter_always(this_fn, call_site);
    }
}

// + foo(a=1) { // hint
// ^^^^^^   ^^^         <-- push+1
//       ^^^            <-- param
//              ^^^^^^^ <-- hint

//   } = 1 // foo() #2
// ^^^     ^^^^^^^^^^^  <-- push-1
//    ^^^^              <-- return

// + foo(a=1) {} = 1 // hint
// ^^^^^^   ^^^              <-- push+1
//       ^^^                 <-- param
//                   ^^^^^^^ <-- hint
//             ^             <-- push-1
//              ^^^^         <-- return

void __cyg_profile_func_exit_always(void *this_fn, void *call_site) {
    void       * fa =                this_fn  ; // function address not necessarily unique; see linker -Wl,--whole-archive option
    CWRAP_DATA * cw = (CWRAP_DATA *) call_site; // cwrap data
    cwrap_data_sanity_check(fa, cw);
    if (cw->calls <= 10000) {
#ifdef COR_XXHASH_STACK_COR_SWITCHES
        cor_xxhash_stack(2);
#endif
        const char * append = cwrap_log_append_get();
        const char * result = cwrap_log_result_get();
        if   ((      cwrap_log_output_curt)
        &&    (cw == cwrap_log_cor[cor_id].unique)) { cwrap_log_pop(-1, 0 /*    append */, 0 /* outside */, 1 /* not plain */, ") {}%%s%%s //"     "%%s%%s", NULL == result ? "" : " = ", NULL == result ? "" : result,           NULL == append ? "" : " ", NULL == append ? "" : append); cwrap_log_cor[cor_id].unique = NULL; }
        else                                        { cwrap_log_pop(-1, 1 /* no append */, 0 /* outside */, 1 /* not plain */,    "}%%s%%s // %%s() %%s%%s", NULL == result ? "" : " = ", NULL == result ? "" : result, cw->name, NULL == append ? "" : " ", NULL == append ? "" : append);                                      }
    }
    if (cwrap_log_output_unwind) {
        cwrap_sanity_check_stack();
    }
}

void __cyg_profile_func_exit(void *this_fn, void *call_site) {
    void       * fa =                this_fn  ; // function address not necessarily unique; see linker -Wl,--whole-archive option
    CWRAP_DATA * cw = (CWRAP_DATA *) call_site; // cwrap data
    cwrap_data_sanity_check(fa, cw);
    if (cwrap_log_quiet_until_cw == NULL) {
        __cyg_profile_func_exit_always(this_fn, call_site);
    }
}

void cwrap_log_stats(void) {
    int indent_save = cwrap_log_cor[cor_id].indent;
    cwrap_log_cor[cor_id].indent = 0; // flatten any indent in case deep in the stack causing snprintf issues
    __cyg_profile_func_enter_always(NULL, &cwrap_data_cwrap_log_stats);
    cwrap_log_append("[%%s() ignores verbosity!]", __FUNCTION__);
    int i = 0;
    int j = 0;
    int k = 0;
    CWRAP_DATA * cwd = cwrap_data_start;
    do {
        if (cwd->calls > 0) {
            cwrap_log("%%'d calls to %%'d of %%'d function variation(s) for %%s()\\n", cwd->calls, cwd->variation_x, cwd->of_y_variations, &cwd->name[0]);
            i += cwd->calls;
            j ++;
        }
        k ++;
        cwd = cwd->next;
    } while (cwd);
    if(cwrap_log_verbosity >= cwrap_data_cwrap_log_stats.verbosity){ cwrap_log_append("%%'d calls to %%'d of %%'d functions instrumented\\n", i, j, k); }
    __cyg_profile_func_exit_always(NULL, &cwrap_data_cwrap_log_stats);
    cwrap_log_cor[cor_id].indent = indent_save;
}

typedef enum CWRAP_CLAUSE_TYPE {
    CWRAP_CLAUSE_TYPE_ANY      = 1,
    CWRAP_CLAUSE_TYPE_FILE        ,
    CWRAP_CLAUSE_TYPE_FUNCTION
} CWRAP_CLAUSE_TYPE;

typedef struct CWRAP_CLAUSE CWRAP_CLAUSE;

typedef struct CWRAP_CLAUSE {
    int                 pos;
    int                 len;
    char              * text; // copy of clause, zero terminated
    int                 verbosity;
    char              * keyword;
    int                 matches;
    CWRAP_CLAUSE_TYPE   type;
    CWRAP_CLAUSE      * next;
} CWRAP_CLAUSE;

#define CWRAP_LOG_VERBOSITY_CLAUSE_SEPARATOR   '/'
#define CWRAP_LOG_VERBOSITY_CLAUSE_MATCH_START "-"

void cwrap_log_verbosity_set(const char * verbosity) { // e.g. 1/9=file-libarchive/9=function-cor_switch/9=function-::~
    __cyg_profile_func_enter_always(NULL, &cwrap_data_cwrap_log_verbosity_set);
    cwrap_log_params("verbosity=%%s", verbosity);
    cwrap_log_append("[%%s() ignores verbosity!]", __FUNCTION__);

    int  pos = -1;
    char c   =  1;

    CWRAP_CLAUSE * clause_next = (CWRAP_CLAUSE *) alloca(sizeof(CWRAP_CLAUSE));
    CWRAP_CLAUSE * clause_head = clause_next;
    CWRAP_CLAUSE * clause_this;
    int            clause_len;
    goto CLAUSE_INIT;
    do {
        c = verbosity[pos];
        if ((CWRAP_LOG_VERBOSITY_CLAUSE_SEPARATOR == c) || (0 == c)) {
            // come here if end of verbosity clause
                   clause_len        = pos - clause_this->pos;
                   clause_this->text = (char *) alloca(1 + clause_len);
            memcpy(clause_this->text, &verbosity[clause_this->pos], clause_len);
                   clause_this->text[0 + clause_len] = 0; // copy of clause, zero terminated so strcasestr() will work below

            clause_this->len       = clause_len;
            clause_this->verbosity = atoi(&verbosity[clause_this->pos]);
            clause_this->type      = strcasestr(clause_this->text, "=file"    ) ? CWRAP_CLAUSE_TYPE_FILE     : clause_this->type;
            clause_this->type      = strcasestr(clause_this->text, "=function") ? CWRAP_CLAUSE_TYPE_FUNCTION : clause_this->type;
            clause_this->keyword   = strcasestr(clause_this->text, CWRAP_LOG_VERBOSITY_CLAUSE_MATCH_START);
            if (clause_this->keyword) {
                // come here if ~ is found, point to the char after ~
                if (CWRAP_CLAUSE_TYPE_ANY == clause_this->type) { cwrap_log("ERROR: CWRAP: Found ~<keyword> but cannot find ={file|function} in clause '%%s'\\n", clause_this->text); exit(1); }
                clause_this->keyword ++;
            }
            else if (CWRAP_CLAUSE_TYPE_ANY != clause_this->type) { cwrap_log("ERROR: CWRAP: Cannot find ~<keyword> in clause '%%s'\\n", clause_this->text); exit(1); }
            //cwrap_log("len=%%d clause=%%.*s verbosity=%%d type=%%s keyword=%%s", clause_this->len, clause_this->len, &verbosity[clause_this->pos], clause_this->verbosity, (CWRAP_CLAUSE_TYPE_ANY == clause_this->type) ? "FILE|FUNCTION" : (CWRAP_CLAUSE_TYPE_FILE == clause_this->type) ? "FILE" : "FUNCTION", clause_this->keyword);

            clause_next          = (CWRAP_CLAUSE *) alloca(sizeof(CWRAP_CLAUSE));
            clause_this->next    = clause_next;
            CLAUSE_INIT:;
            clause_next->pos     = pos + 1;
            clause_next->len     = 0;
            clause_next->next    = NULL;
            clause_next->keyword = NULL;
            clause_next->matches = 0;
            clause_next->type    = CWRAP_CLAUSE_TYPE_ANY;
            clause_this          = clause_next;
        }
        pos ++;
    } while (c);

    int i = 0;
    CWRAP_DATA * cwd = cwrap_data_start;
    do {
        cwrap_data_sanity_check(NULL, cwd);
        //debug cwrap_log("i=%%d .verbosity=%%d .name=%%s", i, cwd->verbosity, &cwd->name[0]);

        clause_this = clause_head;
        do {
            if (CWRAP_CLAUSE_TYPE_ANY == clause_this->type) {
                //cwrap_log("general match: set verbosity to %%d for function %%s() from %%s", clause_this->verbosity, &cwd->name[0], &cwd->file[0]);
                cwd->verbosity = clause_this->verbosity;
                clause_this->matches ++;
            }
            else {
                const char * cwrap_text_to_search = (CWRAP_CLAUSE_TYPE_FILE == clause_this->type) ? cwd->file : cwd->name;
                if (strstr(cwrap_text_to_search, clause_this->keyword)) {
                    //cwrap_log("%%s match for clause '%%s': set verbosity to %%d for function %%s() from %%s", (CWRAP_CLAUSE_TYPE_FILE == clause_this->type) ? "FILE" : "FUNCTION", clause_this->text, clause_this->verbosity, &cwd->name[0], &cwd->file[0]);
                    cwd->verbosity = clause_this->verbosity;
                    clause_this->matches ++;
                }
            }
            clause_this = clause_this->next;
        } while (clause_this->next);

        i ++;
        cwd = cwd->next;
    } while (cwd);

    clause_this = clause_head;
    do {
        cwrap_log("verbosity %%d set for %%'d matches in %%'d functions for %%d byte clause '%%s' // type=%%s keyword=%%s", clause_this->verbosity, clause_this->matches, i, clause_this->len, clause_this->text, (CWRAP_CLAUSE_TYPE_ANY == clause_this->type) ? "FILE|FUNCTION" : (CWRAP_CLAUSE_TYPE_FILE == clause_this->type) ? "FILE" : "FUNCTION", clause_this->keyword);
        clause_this = clause_this->next;
    } while (clause_this->next);

    __cyg_profile_func_exit_always(NULL, &cwrap_data_cwrap_log_verbosity_set);
}

void cwrap_log_quiet_until(char * name) {
    __cyg_profile_func_enter_always(NULL, &cwrap_data_cwrap_log_quiet_until);
    cwrap_log_params("name=%%s", name);
    int i = 0;
    CWRAP_DATA * cwd = cwrap_data_start;
    do {
        cwrap_data_sanity_check(NULL, cwd);
        if (strstr(cwd->name, name)) {
            cwrap_log_append("going quiet until function %%s()", &cwd->name[0]);
            goto EARLY_OUT;
        }
        i ++;
        cwd = cwd->next;
    } while (cwd);
    cwrap_log_append("quiet until function not found");
    cwd = NULL;
    EARLY_OUT:;
    cwrap_log_append(" [%%s() ignores verbosity!]", __FUNCTION__);
    __cyg_profile_func_exit_always(NULL, &cwrap_data_cwrap_log_quiet_until);
    cwrap_log_quiet_until_cw = cwd;
}

__attribute__((weak)) int  cor_init_called;

__attribute__((weak)) void cor_init(void)
{
    // this function can be overridden via weak linkage by the cor_init() in cor.c
}

// This function gets called *before* main() and hopefully *before* C++ initialization.
// It is completely silent unless verbosity is being switched on.
// The asm voodoo to make this work is described here [1].
// However, due to pre-main complexity [2] stuff could and can start-up before this :-(
// This also means that atexit() called here might not end up being the last function called too.
// [1] https://stackoverflow.com/questions/2053029/how-exactly-does-attribute-constructor-work
// [2] https://www.gnu.org/software/hurd/glibc/startup.html
int cwrap_log_init_called = 0;

int cwrap_log_init(void)
{
    __asm__ (".section .init \\n call cwrap_log_init \\n .section .text\\n");

    if (cwrap_log_init_called)
        goto EARLY_OUT;

    cwrap_log_init_called ++;

    char * p_env_verbosity                = getenv("CWRAP_LOG_VERBOSITY_SET");
    char * p_env_stats                    = getenv("CWRAP_LOG_STATS");
    char * p_env_num                      = getenv("CWRAP_LOG_NUM");
    char * p_env_show                     = getenv("CWRAP_LOG_SHOW");
    char * p_env_curt                     = getenv("CWRAP_LOG_CURT");
    char * p_env_file                     = getenv("CWRAP_LOG_FILE");
    char * p_env_cor_id                   = getenv("CWRAP_LOG_COR_ID");
    char * p_env_unwind                   = getenv("CWRAP_LOG_UNWIND");
    char * p_env_thread_id                = getenv("CWRAP_LOG_THREAD_ID");
    char * p_env_stack_ptr                = getenv("CWRAP_LOG_STACK_PTR");
    char * p_env_timestamp                = getenv("CWRAP_LOG_TIMESTAMP");
    char * p_env_on_valgrind              = getenv("CWRAP_LOG_ON_VALGRIND");
    char * p_env_quiet_until              = getenv("CWRAP_LOG_QUIET_UNTIL");
    int    stats                          = p_env_stats       ? atoi(p_env_stats      ) : 0;
    int    show                           = p_env_show        ? atoi(p_env_show       ) : 0;
           cwrap_log_output_num           = p_env_num         ? atoi(p_env_num        ) : 0;
           cwrap_log_output_curt          = p_env_curt        ? atoi(p_env_curt       ) : CWRAP_LOG_CURT;
           cwrap_log_output_file          = p_env_file        ? atoi(p_env_file       ) : CWRAP_LOG_FILE;
           cwrap_log_output_cor_id        = p_env_cor_id      ? atoi(p_env_cor_id     ) : CWRAP_LOG_COR_ID;
           cwrap_log_output_unwind        = p_env_unwind      ? atoi(p_env_unwind     ) : CWRAP_LOG_UNWIND;
           cwrap_log_output_thread_id     = p_env_thread_id   ? atoi(p_env_thread_id  ) : CWRAP_LOG_THREAD_ID;
           cwrap_log_output_stack_pointer = p_env_stack_ptr   ? atoi(p_env_stack_ptr  ) : CWRAP_LOG_STACK_PTR;
           cwrap_log_output_elapsed_time  = p_env_timestamp   ? atoi(p_env_timestamp  ) : CWRAP_LOG_TIMESTAMP;
           cwrap_log_output_on_valgrind   = p_env_on_valgrind ? atoi(p_env_on_valgrind) : CWRAP_LOG_ON_VALGRIND;
    setlocale(LC_NUMERIC, "");
    if (p_env_verbosity) {
        cwrap_log_plain("cwrap_log_init() {} // CWRAP_LOG: _VERBOSITY_SET=%%s (<verbosity>[={file|function}-<keyword>][/...]) _QUIET_UNTIL=%%s _STATS=%%d _SHOW=%%d _CURT=%%d _FILE=%%d _NUM=%%d _COR_ID=%%d _THREAD_ID=%%d _STACK_PTR=%%d _TIMESTAMP=%%d _UNWIND=%%d _ON_VALGRIND=%%d\\n",
            p_env_verbosity,
            p_env_quiet_until,
            stats,
            show,
            cwrap_log_output_curt,
            cwrap_log_output_file,
            cwrap_log_output_num,
            cwrap_log_output_cor_id,
            cwrap_log_output_thread_id,
            cwrap_log_output_stack_pointer,
            cwrap_log_output_elapsed_time,
            cwrap_log_output_unwind,
            cwrap_log_output_on_valgrind);
        cwrap_data_cwrap_log_verbosity_set.verbosity = 1;
        cwrap_log_verbosity_set(p_env_verbosity);
#ifdef COR_XXHASH_STACK
        cwrap_log_verbosity_set("9=function~cor_xxhash_stack");
#endif
        if (p_env_quiet_until) {
            cwrap_log_quiet_until(p_env_quiet_until);
        }
        if (stats) {
            atexit(cwrap_log_stats);
        }
    }
    cor_init_called = 0;
    cor_init();
    if (show) {
        cwrap_log_show(NULL);
        exit(0);
    }

    EARLY_OUT:;
    return 0;
}

#if 0
// this method seems promising and .preinit works before .init section, but worked on Zeek but not on cwrap tests?!
// see https://stackoverflow.com/questions/32700494/executing-init-and-fini
static void preinit(int argc, char **argv, char **envp) {
    cwrap_log_init();
}

__attribute__((section(".preinit_array"), used)) static typeof(preinit) *preinit_p = preinit;
#endif

#ifdef __cplusplus
}
#endif
EOF

    close $out;
} # using_undefind_error_write_cwrap_c()


sub create_cwrap_h_if_necessary() {
    my $cwrap_file = "cwrap.h";
    $log .= sprintf qq[%f - cwrap: checking if new contents different to old contents for header file: %s\n], Time::HiRes::time() - $ts, $cwrap_file;
    my $new_file_contents = sprintf <<EOF;
#ifdef __cplusplus
extern "C" {
#endif

#ifndef CWRAP_LOG_INIT_REF
#define CWRAP_LOG_INIT_REF
// help to force inclusion of cwrap_log_init() even if static library shenanigans during build process
// https://stackoverflow.com/questions/2991927/how-to-force-inclusion-of-an-object-file-in-a-static-library-when-linking-into-e
extern int cwrap_log_init(void);
__attribute__((weak)) void * p_cwrap_log_init = (void *) &cwrap_log_init; // fixme
#endif

#define CWRAP      (1)
#define COR_ID     (1)

extern __thread int    cor_id;
extern __thread char * cor_stack_addr_main;
extern __thread char * cor_stack_addr_help;
extern __thread int    cor_stack_size_main;
extern __thread int    cor_stack_size_help;
extern          int    cor_init_called;
extern          int    cwrap_log_output_on_valgrind;
extern __thread int    cwrap_log_indent[];
extern          char   cwrap_log_spaces[];
extern          int    cwrap_log_verbosity;
extern          void * cwrap_log_quiet_until_cw;
extern          void   cwrap_log(const char * format, ...);
extern          void   cwrap_log_plain(const char * format, ...);
extern          void   cwrap_log_push(int indent_direction, int no_append, const char * format, ...);
extern          void   cwrap_log_pop(int indent_direction, int no_append, int is_inside, int not_plain, const char * format, ...);
extern          int    cwrap_log_get_lines(void);
extern          void   cwrap_log_result(const char * format, ...);
extern          void   cwrap_log_append(const char * format, ...);
extern const    char * cwrap_log_result_get(void);
extern const    char * cwrap_log_append_get(void);
extern          void   cwrap_log_params(const char * format, ...);
extern          char * cwrap_log_dump_hex(const void * pointer, int len, int len_max);
extern          void   cwrap_log_verbosity_set(const char * verbosity);
extern          void   cwrap_log_stats(void);

#ifdef __cplusplus
}
#endif

// The extra indirection is to ensure that the __LINE__ string comes through OK.

#define CWRAP_PARAMS(...) _generic_printf(cwrap_log_params, __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define CWRAP_RESULT(...) _generic_printf(cwrap_log_result, __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define CWRAP_APPEND(...) _generic_printf(cwrap_log_append, __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define CWRAP_DEBUG(...)  _generic_printf(cwrap_log       , __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define CWRAP_PLAIN(...)  _generic_printf(cwrap_log_plain , __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)

#define params_printf(...) _generic_printf(cwrap_log_params, __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define result_printf(...) _generic_printf(cwrap_log_result, __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define append_printf(...) _generic_printf(cwrap_log_append, __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define  debug_printf(...) _generic_printf(cwrap_log       , __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)
#define  plain_printf(...) _generic_printf(cwrap_log_plain , __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)

#define _generic_printf(_function, _pretty_function, _counter, ...) __generic_printf(_function, _pretty_function, _counter, __VA_ARGS__)

#define __generic_printf(__function, __pretty_function, __counter, ...) __asm__(".pushsection __cwrap, \\\"S\\\", \@note; .int \" #__counter \"; .asciz \\\"%0\\\"; .popsection\\n\\t" : : "s" ( __pretty_function ) ); \\
    extern int cwrap_data_verbosity_dummy_##__counter; /* todo; implement cwrap_log_quiet_until_cw here! */ \\
    if((cwrap_log_verbosity >= cwrap_data_verbosity_dummy_##__counter)  /* get replaced in assembler file! */ \\
    && (NULL                == cwrap_log_quiet_until_cw              )){ __function(__VA_ARGS__); }

// note: CWRAP_PRINTF() uses regular printf() if function verbosity too low, otherwise promotes to cwrap_log(), i.e. always prints one way or the other!

#define CWRAP_PRINTF(...)  _promote_printf(cwrap_log, __PRETTY_FUNCTION__, __COUNTER__, __VA_ARGS__)

#define _promote_printf(_function, _pretty_function, _counter, ...) __promote_printf(_function, _pretty_function, _counter, __VA_ARGS__)

#define __promote_printf(__function, __pretty_function, __counter, ...) __asm__(".pushsection __cwrap, \\\"S\\\", \@note; .int \" #__counter \"; .asciz \\\"%0\\\"; .popsection\\n\\t" : : "s" ( __pretty_function ) ); \\
    extern int cwrap_data_verbosity_dummy_##__counter; /* todo; implement cwrap_log_quiet_until_cw here! */ \\
    if((cwrap_log_verbosity >= cwrap_data_verbosity_dummy_##__counter)  /* get replaced in assembler file! */ \\
    && (NULL                == cwrap_log_quiet_until_cw              )){ __function(__VA_ARGS__); } else { printf(__VA_ARGS__); }

// note: only use ... below to avoid "warning: ISO C++ does not permit named variadic macros" described here: https://stackoverflow.com/questions/4786649/are-variadic-macros-nonstandard
// todo: better integrate asserts with CWRAP_LOG_*() functions
#define CWRAP_ASSERT_STRERROR(CONDITION,...) if (!(CONDITION)) { printf("%%05u:%%s: ERROR: assertion: %%d: %%s; ", __LINE__, __FILE__, errno, strerror(errno)); printf(__VA_ARGS__); fflush(stdout); exit(EXIT_FAILURE); }
#define CWRAP_ASSERT_INTERNAL(CONDITION,...) if (!(CONDITION)) { printf("%%05u:%%s: ERROR: assertion: "          , __LINE__, __FILE__                        ); printf(__VA_ARGS__); fflush(stdout); exit(EXIT_FAILURE); }
EOF

    # example non-fPIC assembler:     .pushsection __cwrap, "S", \@note; .int 9; .asciz "\$__PRETTY_FUNCTION__.3184"; .popsection
    # example non-fPIC assembler: ...
    # example non-fPIC assembler:     movl  cwrap_log_verbosity\@GOTPCREL(%rip), %eax
    # example non-fPIC assembler:     cmpl  %eax, 36+cwrap_log_verbosity_dummy\@GOTPCREL(%rip)
    # example non-fPIC assembler:     jle   .L23

    my $old_file_contents = `cat $cwrap_file 2>&1`;
    if ($old_file_contents ne $new_file_contents) {
        $log .= sprintf qq[%f - cwrap: new contents differ from old contents; writing missing cwrap header to: %s\n], Time::HiRes::time() - $ts, $cwrap_file;
        open(my $out, '>', $cwrap_file) || cwrap_die(sprintf qq[%f ERROR: cwrap: cannot open file for writing: %s\n], Time::HiRes::time() - $ts, $cwrap_file);
        syswrite($out, $new_file_contents);
        close $out;
    }
}

sub compress_demangled_name {
    my ($demangled_name, $debug_expected) = @_;
    my $debug_result;
    my $demangled_name_orig = $demangled_name;

    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~<[^<>]*>~!!~g) {} # remove all <..>
    $debug_result .= sprintf qq[- compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    #while($demangled_name =~ s~\{[^\{\}]+\}~{}~) {} # remove all {..}
    #$debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug);

    while($demangled_name =~ s~ const\&*~~g) {} # remove const&
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~lambda\([^\(\)]*\)\#\d+~lambda||~g) {} # remove all lambda(..)#n
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~\(\)~||~) {} # remove ()
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~\(([\*\&]+)\)~|*|~) {} # remove (*) or (*&)
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~\(anonymous namespace\)~|anonymous-namespace|~) {} # caf::(anonymous namespace)::fill_builtins()
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~\([^\(\)\*\&][^\(\)]*\)~||~) {} # remove (..) except not (*..) and not (&..)
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~lambda\|\|\#\d+~lambda||~g) {} # remove all lambda(..)#n due to nesting
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~!!~<>~g) {}
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~\|([^\|]*)\|~($1)~g) {}
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~unnamed type#\d+~unnamed-type~) {} # deal with unnamed type #1
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~^((.*?)<>|void)\s+~~) {} # std::tuple<> std::forward_as_tuple<>()
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    while($demangled_name =~ s~[^:\s]+\s+([^:\s]+::)~$1~) {} # std::vector<>& caf::default_sum_type_access<>::get<>() -> std::caf::default_sum_type_access<>::get<>()
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    $demangled_name =~ s~\(\)$~~; # remove single empty trailing () which normally contains function parameters
    $debug_result .= sprintf qq[- test: compress_demangled_name(): %s\n\n], $demangled_name if ($debug_expected);

    if ($debug_expected) {
        printf qq[%s], $debug_result if ($demangled_name ne $debug_expected);
        cmp_ok($demangled_name, 'eq', $debug_expected, sprintf qq[test: compressed %d bytes unique demangled name to expected %d bytes non-unique name: %s], length($demangled_name_orig), length($debug_expected), $debug_expected);
        exit(1) if ($demangled_name ne $debug_expected);
    }

    return $demangled_name;
} # compress_demangled_name()

ONLY_REQUIRED_FOR_SUBS:;

1;
