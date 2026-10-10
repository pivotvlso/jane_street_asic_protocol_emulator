#!/usr/bin/perl
use strict;
use warnings;

my %opcodes = (
    "ADD" => 0x0, "SUB" => 0x1, "AND" => 0x2, "XOR" => 0x3, "SHR" => 0x4, "SHL" => 0x5, "NOP" => 0x6, "LOADIB" => 0x7,
    "SET0" => 0x8, "SET1" => 0x9, "LOADI" => 0xA, "LOAD" => 0xB, "STORE" => 0xC,
    "JMP" => 0xD, "JMPNZ" => 0xE, "JMPC" => 0xF
);

my $file = $ARGV[0] or die "Usage: $0 <file.asm>\n";
open(my $fh, '<', $file) or die "Cannot open $file: $!\n";
my @lines = <$fh>;
close($fh);

my $pc_op = 0;
my @instructions;

foreach my $line (@lines) {
    chomp $line;
    my $expect = "";
    if ($line =~ /\[EXPECT:\s*(.*?)\]/) {
        $expect = $1;
    }

    $line =~ s/\/\/.*//; # Strip comments
    $line =~ s/^\s+|\s+$//g; # Trim whitespace
    next if $line eq "";
    
    if ($line =~ /^([A-Za-z0-9_]+):$/) {
        next;
    }
    
    my @parts = split(/\s+/, $line);
    my $op = uc($parts[0]);
    next if (!defined $opcodes{$op});
    
    my $arg = defined $parts[1] ? $parts[1] : "";
    push @instructions, { pc => $pc_op, op => $op, arg => $arg };
    
    $pc_op += 1;
}

my $assertfile = $file;
$assertfile =~ s/\.asm$/_assert.vh/;
my $core_id = "";
if ($file =~ /core(\d)/) {
    $core_id = $1;
} elsif ($file =~ /tx/) {
    $core_id = "0";
}

if ($core_id ne "") {
    open(my $aout, '>', $assertfile) or die "Cannot write to $assertfile: $!\n";
    print $aout "reg [6:0] last_pc_${core_id};\n";
    print $aout "reg [7:0] last_acc_${core_id};\n";
    print $aout "reg [7:0] last_b_${core_id};\n";
    print $aout "always \@(posedge clk) begin\n";
    print $aout "    if (dut.core${core_id}.run && !dut.core${core_id}.mem_stall) begin\n";
    print $aout "        last_pc_${core_id} <= dut.core${core_id}.pc_op;\n";
    print $aout "        last_acc_${core_id} <= dut.core${core_id}.acc;\n";
    print $aout "        last_b_${core_id} <= dut.core${core_id}.b_reg;\n";
    print $aout "    end\n";
    print $aout "end\n";
    print $aout "always \@(posedge clk) begin\n";
    print $aout "    if (dut.core${core_id}.run) begin\n";
    print $aout "        case (last_pc_${core_id})\n";
    
    foreach my $inst (@instructions) {
        my $cur_pc = $inst->{pc};
        my $op = $inst->{op};
        my $arg = $inst->{arg};
        
        my $cond = "";
        
        if ($op eq "LOADI" && $arg =~ /^[0-9]+$/) {
            $cond = sprintf("dut.core${core_id}.acc === 8'h%02X", $arg);
        } elsif ($op eq "LOADI" && $arg =~ /^0x([0-9A-Fa-f]+)$/) {
            $cond = sprintf("dut.core${core_id}.acc === 8'h%02X", hex($1));
        } elsif ($op eq "STORE") {
            if ($arg =~ /^R(\d+)$/) {
                my $num = $1;
                if ($num <= 3) {
                    $cond = "dut.core${core_id}.r_regs[$num] === last_acc_${core_id}";
                }
            } elsif ($arg eq "B") {
                $cond = "dut.core${core_id}.b_reg === last_acc_${core_id}";
            }
        } elsif ($op eq "LOAD") {
            if ($arg =~ /^R(\d+)$/) {
                my $num = $1;
                if ($num <= 3) {
                    $cond = "dut.core${core_id}.acc === dut.core${core_id}.r_regs[$num]";
                }
            } elsif ($arg eq "B") {
                $cond = "dut.core${core_id}.acc === dut.core${core_id}.b_reg";
            }
        }
        
        if ($cond ne "") {
            printf $aout "            7'h%02X: if (!(%s)) \$display(\"ASSERTION FAILED CPU %s PC %%02X: Expected %s %s, got ACC=%%h B=%%h R2=%%h R3=%%h (last_acc=%%h)\", last_pc_${core_id}, dut.core%s.acc, dut.core%s.b_reg, dut.core%s.r_regs[2], dut.core%s.r_regs[3], last_acc_${core_id});\n", 
                         $cur_pc, $cond, $core_id, $op, $arg, $core_id, $core_id, $core_id, $core_id;
        }
    }
    
    print $aout "        endcase\n";
    print $aout "    end\n";
    print $aout "end\n";
    close($aout);
    print "Generated $assertfile\n";
}
