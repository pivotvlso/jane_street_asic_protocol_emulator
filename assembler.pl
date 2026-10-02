#!/usr/bin/perl
use strict;
use warnings;

my %opcodes = (
    "ADD" => 0x0, "SUB" => 0x1, "AND" => 0x2, "XOR" => 0x3, "SHR" => 0x4, "SHL" => 0x5, "NOP" => 0x6, "RETI" => 0x7,
    "SET0" => 0x8, "SET1" => 0x9, "LOADI" => 0xA, "LOAD" => 0xB, "STORE" => 0xC,
    "JMP" => 0xD, "JMPNZ" => 0xE, "JMPC" => 0xF
);

my %registers = (
    "ACC" => 0, "B" => 1, "R2" => 2, "R3" => 3, "TX_FIFO" => 4, "RX_FIFO" => 5, "PIN_STATE" => 6, 
    "TIMER_L" => 7, "TIMER_H" => 8, "FLAGS" => 9, "R4" => 10, "R5" => 11, "R6" => 12, "R7" => 13, "R8" => 14, "PIN_DIR" => 15
);

my $file = $ARGV[0] or die "Usage: $0 <file.asm>\n";
open(my $fh, '<', $file) or die "Cannot open $file: $!\n";

my @lines = <$fh>;
close($fh);

my %labels;
my $pc = 0;
my @instructions;

# Pass 1: Resolve Labels
foreach my $line (@lines) {
    chomp $line;
    $line =~ s/\/\/.*//; # Remove comments
    $line =~ s/^\s+|\s+$//g; # Trim whitespace
    next if $line eq "";
    
    if ($line =~ /^([A-Za-z0-9_]+):$/) {
        $labels{$1} = $pc;
        next;
    }
    
    my @parts = split(/\s+/, $line);
    my $op = uc($parts[0]);
    if (!defined $opcodes{$op}) {
        die "Unknown opcode: $op\n";
    }
    my $op_val = $opcodes{$op};
    
    push @instructions, { line => $line, op => $op, args => \@parts, pc => $pc };
    
    if ($op_val <= 0x7) {
        $pc += 1;
    } elsif ($op_val <= 0xC) {
        $pc += 2;
    } else {
        $pc += 3;
    }
}

if ($pc > 128) {
    warn "WARNING: Program size ($pc nibbles) exceeds 128-nibble limit!\n";
}

# Pass 2: Generate Hex
my @hex_out;
foreach my $inst (@instructions) {
    my $op = $inst->{op};
    my $op_val = $opcodes{$op};
    my @parts = @{$inst->{args}};
    
    push @hex_out, sprintf("%X", $op_val);
    
    if ($op_val >= 0x8 && $op_val <= 0xC) {
        my $arg = uc($parts[1]);
        my $val = 0;
        if (defined $registers{$arg}) {
            $val = $registers{$arg};
        } elsif ($arg =~ /^[0-9]+$/) {
            $val = $arg;
        } else {
            die "Unknown register/value: $arg\n";
        }
        push @hex_out, sprintf("%X", $val);
    } elsif ($op_val >= 0xD) {
        my $label = $parts[1];
        if (!defined $labels{$label}) {
            die "Unknown label: $label\n";
        }
        my $addr = $labels{$label};
        push @hex_out, sprintf("%02X", $addr);
    }
}

# Write output (One nibble per line as 0x0N for Verilog $readmemh)
my $outfile = $file;
$outfile =~ s/\.asm$/.hex/;
open(my $out, '>', $outfile) or die "Cannot write to $outfile: $!\n";
my $full_string = join("", @hex_out);
foreach my $char (split //, $full_string) {
    print $out "0$char\n";
}
close($out);
print "Compiled $file -> $outfile ($pc nibbles)\n";
