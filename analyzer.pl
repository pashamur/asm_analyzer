#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor qw(:constants);

sub print_help
{
    print "\nUsage: \n    analyzer.pl  [options]  <obj>  <src>\n";
    print "Options:\n";
    print "    -l, --line \t activates line mode:  -l 42 to get information about line 42\n";
    print "    -h, --help \t (or no parameters) brings up this message\n";
    print "Example: \n";
    print "    perl analyzer.pl --line 54 debug/myfile.o myfile.cpp\n";
    print "Description:\n";
    print "    Prints out an analysis of the src file's source code, using the program objdump.\n";
    print "    Specifying the source file is optional if the source file is a C++ file with the same\n";
    print "    name as the object file. The object file/executable should be compiled with -g (debug) flag.\n\n";
}
sub strip_slashes
{
    my $dir = $_[0];
    $dir =~ s/.*\/(.*)$/$1/;
    return $dir;
}

if($#ARGV < 0){
    print_help();
    exit();
}

my $help = 0;
my $queried_line;

GetOptions ("line=i" => \$queried_line,
            "help" => \$help);

my $source_file;
my $object_file;
my $line_mode = defined($queried_line);

if($help){
    print_help();
    exit(0);
}
# Loop to parse the command line arguments -> -l -h and the source/object files.
for my $arg (@ARGV)
{
    if(-s $arg && ($arg =~ /.*\.cpp$/ || $arg =~ /.*\.c$/)){
        $source_file = $arg;
    }
    elsif(-s $arg && (($arg =~ /.*\.o$/) || -x $arg)){
        $object_file = $arg;
    }
    else{
        print RED, "\nERROR: ".$arg." does not exist or is not recognized as a valid argument.\n", RESET;
        print_help();
        exit(1);
    }
}
if(!defined($object_file)){
    print RED, "ERROR: No object file specified. ABORT.\n", RESET;
    print_help();
    exit(1);
}
if(!defined($source_file)){                                                 # if source file not specified, try to find it
    if(-s $object_file.".cpp"){
        $source_file = $object_file.".cpp";
    }     
    elsif(-s substr($object_file, 0, -2).".cpp"){                           # check for .cpp file assosciated with a .o file
        $source_file = substr($object_file, 0, -2).".cpp";
    }
    elsif(-s strip_slashes(substr($object_file, 0, -2).".cpp")){            #try searching in current directory
        $source_file = strip_slashes(substr($object_file, 0, -2).".cpp");
    }
    elsif(-s strip_slashes($object_file.".cpp")){
        $source_file = strip_slashes($object_file.".cpp");
    }
    else{
        print RED, "\nERROR: No source file specified. ABORT.\n", RESET;
        print_help();
        exit(1);
    }
}

#print "\nDEBUG: SOURCE = $source_file , OBJ = $object_file\n";

my @lines = map {"$_\n"} split(/\n/,`objdump -d -l -C $object_file`);
my %codefreq = ();
my %numjumps = ();
my %numcalls = ();
my @line_mode_data = ();
open(SOURCE, $source_file);
my @sourcelines = <SOURCE>;
close(SOURCE);
$object_file = strip_slashes($object_file);
$source_file = strip_slashes($source_file);

for (my $i = 0; $i<scalar(@lines); $i++)
{
    my $line = $lines[$i];
    if(defined($queried_line) && $line =~ /$source_file:$queried_line\s*$/){
        $i++;
        while ($i<scalar(@lines) && $lines[$i] =~ /^[ ]*[0-9a-f]+:/){
            push(@line_mode_data, $lines[$i]);
            $i++;
        }
        $i--;
    }
    elsif(!defined($queried_line) && $line =~ /$source_file/){
        $line =~ s/^.*$source_file:(\d+)/$1/;
        my $cur_line_counter = 0;
        my $cur_num_jumps = 0;
        my $cur_num_calls = 0;
        $i++;
        while ($i<scalar(@lines) && $lines[$i] =~ /^[ ]*[0-9a-f]+:/)
        {
            if($lines[$i] =~ /.*\s(call|callq)\s.+/){
                $cur_num_calls++;
            }
            elsif($lines[$i] =~ /.*\s(jmpq|jne|je|ja|jbe|jmp)\s.+/){
                $cur_num_jumps++;
            }
            $cur_line_counter++;
            $i++;
        }
        $i--;
        if(!exists($codefreq{int($line)})){
            $codefreq{int($line)} = $cur_line_counter;
            $numjumps{int($line)} = $cur_num_jumps;
            $numcalls{int($line)} = $cur_num_calls;
        }
        else{
            $codefreq{int($line)} += $cur_line_counter;
            $numjumps{int($line)} += $cur_num_jumps;
            $numcalls{int($line)} += $cur_num_calls;
        }
    }
}

if($line_mode){
    foreach my $line (@line_mode_data)
    {
        print $line;
    }
    exit(0);
}

print sprintf("%4s |%4s |%3s |%4s | %s", "Line", "ASM", "JMP", "CALL", "          Source Code");
print "\n---------------------------------------------------------------\n";

for(my $i = 1; $i<scalar(@sourcelines)+1; $i++){
    if(!exists $codefreq{$i}){
        $codefreq{$i} = 0;
        $numjumps{$i} = 0;
        $numcalls{$i} = 0;
    }
    print sprintf("%4d |%4d |%3d |%4d |   %s", $i, $codefreq{$i}, $numjumps{$i}, $numcalls{$i}, $sourcelines[$i-1]);
}




