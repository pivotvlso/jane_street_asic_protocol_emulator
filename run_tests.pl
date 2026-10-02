#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);
use File::Copy qw(move);

print "==============================================\n";
print " Quad-Core Protocol Emulator Verification \n";
print "==============================================\n\n";

# 1. Compile the assembly files
print "--> Step 1: Compiling Assembly Firmware...\n";
my @asm_files = glob("protocols/*/*.asm");
foreach my $asm_file (@asm_files) {
    print "    Assembling $asm_file...\n";
    system("perl assembler.pl $asm_file");
}

# Ensure output directory exists
unless (-d "verif_output") {
    make_path("verif_output");
}

# 2. Run Verilog testbenches
print "\n--> Step 2: Running Icarus Verilog Testbenches...\n";
my @test_files = sort(glob("tests/test_*.v"));

# Filter tests if arguments are provided (e.g. perl run_tests.pl 1_4)
if (@ARGV) {
    my @filtered = ();
    foreach my $test (@test_files) {
        foreach my $arg (@ARGV) {
            if ($test =~ /$arg/) {
                push(@filtered, $test);
                last;
            }
        }
    }
    @test_files = @filtered;
    print "Filtering tests matching: " . join(", ", @ARGV) . "\n";
}

my $passed = 0;
my $total = scalar(@test_files);

foreach my $test (@test_files) {
    my $test_name = basename($test, ".v");
    my $out_file = "verif_output/$test_name.out";
    
    # Compile the Verilog testbench
    my $comp_res = `iverilog -o $out_file -c filelist/filelist.f $test 2>&1`;
    if ($? != 0) {
        print "❌ [$test_name] FAILED TO COMPILE RTL\n";
        print "$comp_res\n";
        next;
    }
    
    # Execute the simulation
    my $sim_res = `vvp $out_file 2>&1`;
    
    # Cleanup: Move the generated VCD file into the verif_output directory
    my $vcd_name = "$test_name.vcd";
    if (-e $vcd_name) {
        move($vcd_name, "verif_output/$vcd_name");
    }
    
    # Parse output for Success/Fail
    if ($sim_res =~ /FAILED/ || $? != 0) {
        print "❌ [$test_name] FAILED\n";
        print "   --- Simulation Output ---\n";
        $sim_res =~ s/\n/\n   /g;
        print "   $sim_res\n";
    } else {
        print "✅ [$test_name] PASSED\n";
        $passed++;
    }
}

print "\n==============================================\n";
print " Verification Complete: $passed/$total Tests Passed\n";
print "==============================================\n";

if ($passed == $total) {
    print "🚀 ALL SYSTEMS GO! Silicon is ready for Tapeout.\n";
}
