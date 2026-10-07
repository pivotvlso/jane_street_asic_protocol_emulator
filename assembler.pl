#!/usr/bin/perl
use strict;
use warnings;

my %opcodes = (
    "ADD" => 0x0, "SUB" => 0x1, "AND" => 0x2, "XOR" => 0x3, "SHR" => 0x4, "SHL" => 0x5, "NOP" => 0x6,
    "SET0" => 0x8, "SET1" => 0x9, "LOADI" => 0xA, "LOAD" => 0xB, "STORE" => 0xC,
    "JMP" => 0xD, "JMPNZ" => 0xE, "JMPC" => 0xF
);

my %registers = (
    "ACC" => 0, "B" => 1, "R2" => 2, "R3" => 3, "TX_FIFO" => 4, "RX_FIFO" => 5, "PIN_STATE" => 6, 
    "TIMER_L" => 7, "TIMER_H" => 8, "FLAGS" => 8, "SHARED_0" => 9, "SHARED_1" => 10, 
    "R4" => 11, "R5" => 12, "R6" => 13, "R7" => 14, "PIN_DIR" => 15
);

my $file = $ARGV[0] or die "Usage: $0 <file.asm>\n";
open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
my @lines = <$fh>;
close($fh);

my $outfile = $file;
$outfile =~ s/\.asm$/.hex/;
open(my $out, '>', $outfile) or die "Cannot write to $outfile: $!\n";

foreach my $line (@lines) {
    # Strip comments
    $line =~ s/\/\/.*//; 
    # Trim whitespace
    $line =~ s/^\s+|\s+$//g; 
    next if $line eq "";
    
    # We do not process labels; if it's a label, skip it
    next if $line =~ /:/;
    
    # Also skip [EXPECT: ...] test assertions
    next if $line =~ /\[EXPECT:/;
    
    my @parts = split(/\s+/, $line);
    my $op = uc($parts[0]);
    if (!defined $opcodes{$op}) {
        die "Unknown opcode: $op\n";
    }
    my $op_val = $opcodes{$op};
    
    # Output the opcode nibble
    print $out sprintf("0%X\n", $op_val);
    
    # If it has an operand (either a register string or a raw number/hex)
    if (scalar(@parts) > 1) {
        my $arg = uc($parts[1]);
        my $val = 0;
        if (defined $registers{$arg}) {
            $val = $registers{$arg};
        } elsif ($arg =~ /^0x([0-9A-Fa-f]+)$/) {
            $val = hex($1);
        } elsif ($arg =~ /^[0-9]+$/) {
            $val = $arg;
        } else {
            die "Unknown register/value: $arg\n";
        }
        
        # If it's LOADI or JUMP, output 2 nibbles
        if ($op_val == 0xA || $op_val >= 0xD) {
            my $hex_str = sprintf("%02X", $val);
            my @chars = split(//, $hex_str);
            print $out "0$chars[0]\n0$chars[1]\n";
        } else {
            print $out sprintf("0%X\n", $val);
        }
    }
}
close($out);
print "Compiled $file -> $outfile\n";
