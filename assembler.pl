#!/usr/bin/perl
use strict;
use warnings;

my %opcodes = (
    "ADD" => 0x0, "SUB" => 0x1, "AND" => 0x2, "XOR" => 0x3, "SHR" => 0x4, "SHL" => 0x5, "NOP" => 0x6, "LOADIB" => 0x7,
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

my %labels;
my %label_ids;
my $next_label_id = 0;

my $pc_op = 0;
my $pc_op1 = 0;
my $pc_op2 = 0;

my @instructions;

# Pass 1: Resolve Labels and Pointer States
foreach my $line (@lines) {
    $line =~ s/\/\/.*//; # Strip comments
    $line =~ s/^\s+|\s+$//g; # Trim whitespace
    next if $line eq "";
    
    if ($line =~ /^([A-Za-z0-9_]+):$/) {
        my $label = $1;
        $labels{$label} = { op => $pc_op, op1 => $pc_op1, op2 => $pc_op2 };
        if (!defined $label_ids{$label}) {
            $label_ids{$label} = $next_label_id++;
        }
        next;
    }
    
    # Skip test assertions
    next if $line =~ /\[EXPECT:/;
    
    my @parts = split(/\s+/, $line);
    my $op = uc($parts[0]);
    if (!defined $opcodes{$op}) {
        die "Unknown opcode: $op\n";
    }
    my $op_val = $opcodes{$op};
    
    # Auto-assign label IDs for forward jumps
    if ($op_val >= 0xD) {
        my $label = $parts[1];
        if (!defined $label_ids{$label}) {
            $label_ids{$label} = $next_label_id++;
        }
    }

    
    push @instructions, { op => $op, args => \@parts };
    
    if ($op_val <= 0x6) { # 1-nibble
        $pc_op += 1;
    } elsif ($op_val >= 0x8 && $op_val <= 0xC && $op_val != 0xA) { # 2-nibble
        $pc_op += 1;
        $pc_op1 += 1;
    } elsif ($op_val >= 0xD) { # 2-nibble Jump
        $pc_op += 1;
        $pc_op1 += 1;
    } elsif ($op_val == 0xA || $op_val == 0x7) { # 3-nibble
        $pc_op += 1;
        $pc_op1 += 1;
        $pc_op2 += 1;
    }
}

if ($pc_op > 128) { warn "WARNING: Program size exceeds 128-nibble op limit!\n"; }
if ($pc_op1 > 64) { warn "WARNING: Program size exceeds 64-nibble op1 limit!\n"; }
if ($pc_op2 > 15)  { warn "WARNING: Program size exceeds 15-nibble op2 limit!\n"; }
if ($next_label_id > 16) { warn "WARNING: Exceeded 16 Jump ID limit!\n"; }

# Pass 2: Generate Split-Stream Hex Files
my $base_name = $file;
$base_name =~ s/\.asm$//;

open(my $out_op, '>', "${base_name}_op.hex") or die $!;
open(my $out_op1, '>', "${base_name}_op1.hex") or die $!;
open(my $out_op2, '>', "${base_name}_op2.hex") or die $!;
open(my $out_jmp, '>', "${base_name}_jmp.hex") or die $!;

foreach my $inst (@instructions) {
    my $op = $inst->{op};
    my $op_val = $opcodes{$op};
    my @parts = @{$inst->{args}};
    
    print $out_op sprintf("%X\n", $op_val);
    
    if ($op_val >= 0x8 && $op_val <= 0xC && $op_val != 0xA) {
        my $arg = uc($parts[1]);
        my $val = 0;
        if (defined $registers{$arg}) {
            $val = $registers{$arg};
        } elsif ($arg =~ /^[0-9]+$/) {
            $val = $arg;
        } else {
            die "Unknown register/value: $arg
";
        }
        print $out_op1 sprintf("%X
", $val);
    } elsif ($op_val >= 0xD) {
        my $label = $parts[1];
        if (!defined $label_ids{$label}) {
            die "Unknown label: $label\n";
        }
        my $id = $label_ids{$label};
        print $out_op1 sprintf("%X\n", $id);
    } elsif ($op_val == 0xA || $op_val == 0x7) {
        my $arg = $parts[1];
        my $val = 0;
        if ($arg =~ /^0x([0-9A-Fa-f]+)$/) {
            $val = hex($1);
        } elsif ($arg =~ /^[0-9]+$/) {
            $val = $arg;
        } else {
            die "Unknown immediate for LOADI/LOADIB: $arg\n";
        }
        my $hex_str = sprintf("%02X", $val);
        my @chars = split(//, $hex_str);
        print $out_op1 "$chars[0]\n";
        print $out_op2 "$chars[1]\n";
    }
}

# Write Jump Table (16 bits = {pc_op[6:0], pc_op1[5:0], pc_op2[2:0]})
my @jmp_array = (0) x 16;
foreach my $label (keys %label_ids) {
    my $id = $label_ids{$label};
    if (defined $labels{$label}) {
        my $p_op = $labels{$label}->{op};
        my $p_op1 = $labels{$label}->{op1};
        my $p_op2 = $labels{$label}->{op2};
        print "DEBUG: Label=$label, ID=$id, OP=$p_op, OP1=$p_op1\n";
        my $packed = ($p_op << 10) | ($p_op1 << 4) | $p_op2;
        $jmp_array[$id] = $packed;
    }
}

for (my $i = 0; $i < 16; $i++) {
    print $out_jmp sprintf("%05X\n", $jmp_array[$i]);
}

close($out_op);
close($out_op1);
close($out_op2);
close($out_jmp);

print "Compiled $file -> ${base_name}_*.hex\n";
