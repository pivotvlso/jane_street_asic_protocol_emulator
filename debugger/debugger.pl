#!/usr/bin/perl
use strict;
use warnings;
use IO::Select;
use IO::Socket::INET;
use File::Basename;
use File::Glob ':bsd_glob';

$| = 1;

my %opcodes = (
    "ADD" => 0x0, "SUB" => 0x1, "AND" => 0x2, "XOR" => 0x3, "SHR" => 0x4, "SHL" => 0x5, "NOP" => 0x6, "RETI" => 0x7,
    "SET0" => 0x8, "SET1" => 0x9, "LOADI" => 0xA, "LOAD" => 0xB, "STORE" => 0xC,
    "JMP" => 0xD, "JMPNZ" => 0xE, "JMPC" => 0xF
);

my $current_tb = $ARGV[0] || "tests/test_3_3_i2c_loopback.v";
my $out_file = "verif_output/debugger.out";
my $log_file = "verif_output/debugger_trace.log";

my %cpu_asm_files;
my %asm_source;
my %cpu_state;
my %breakpoints;
my $step_count = 0;
my $paused = 1;
my $sim_finished = 0;
my $log_fh;

sub reset_state {
    %cpu_state = ();
    foreach my $id (0..3) {
        $cpu_state{$id} = {
            time => 0, pc => "00", op => "00", acc => "0", b => "0", r2 => "0", r3 => "0", r4 => "0",
            flags => "0", c => "0", z => "0", pin_dir => "0", pin_out => "0"
        };
    }
    $step_count = 0;
    $paused = 1;
    $sim_finished = 0;
}

sub load_asm {
    my ($id, $file) = @_;
    open my $fh, '<', $file or return;
    my $pc = 0;
    $asm_source{$id} = [];
    while(my $line = <$fh>) {
        chomp $line;
        my $clean = $line;
        $clean =~ s/\/\/.*//;
        $clean =~ s/^\s+|\s+$//g;
        
        if ($clean eq "") {
            push @{$asm_source{$id}}, { text => $line, pc => "" };
            next;
        }
        
        if ($clean =~ /^([A-Za-z0-9_]+):$/) {
            push @{$asm_source{$id}}, { text => $line, pc => sprintf("%02x", $pc) };
            next;
        }
        
        my @parts = split(/\s+/, $clean);
        my $op = uc($parts[0]);
        my $op_val = $opcodes{$op};
        if (!defined $op_val) {
            push @{$asm_source{$id}}, { text => $line, pc => "" };
            next;
        }
        
        push @{$asm_source{$id}}, { text => $line, pc => sprintf("%02x", $pc) };
        
        if ($op_val <= 0x7) { $pc += 1; }
        elsif ($op_val <= 0xC) { $pc += 2; }
        else { $pc += 3; }
    }
    close $fh;
}

sub run_tb {
    my ($tb_file) = @_;
    $current_tb = $tb_file;
    %cpu_asm_files = ();
    %asm_source = ();
    
    if (open my $tb_fh, '<', $tb_file) {
        while (my $line = <$tb_fh>) {
            if ($line =~ /load_cpu_ram\s*\(\s*8'h0([0-3])\s*,\s*"([^"]+)\.hex"\s*\)/) {
                my $cpu_id = $1;
                my $asm_file = "$2.asm";
                if (-e $asm_file) {
                    $cpu_asm_files{$cpu_id} = $asm_file;
                }
            } elsif ($line =~ /\$readmemh\s*\(\s*"([^"]+)\.hex"\s*,\s*dut\.cpu([0-3])_ram\s*\)/) {
                my $asm_file = "$1.asm";
                my $cpu_id = $2;
                if (-e $asm_file) {
                    $cpu_asm_files{$cpu_id} = $asm_file;
                }
            }
        }
        close $tb_fh;
    }
    
    foreach my $id (keys %cpu_asm_files) {
        load_asm($id, $cpu_asm_files{$id});
    }
    
    reset_state();
    
    print "Compiling $tb_file...\n";
    if (system("iverilog -o $out_file -c filelist/filelist.f $tb_file 2>&1") != 0) {
        print "Compilation failed\n";
        return;
    }

    print "Running simulation...\n";
    system("vvp $out_file > $log_file 2>&1");
    
    if (defined $log_fh) {
        close $log_fh;
    }
    open $log_fh, '<', $log_file or die "Could not open trace log\n";
}

run_tb($current_tb);

my $server = IO::Socket::INET->new(
    LocalPort => 8080,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 10
) or die "Couldn't start server on port 8080: $@\n";

print "Debugger UI started at http://localhost:8080\n";

my $sel = IO::Select->new($server);

while (1) {
    if (my @ready = $sel->can_read(0.01)) {
        foreach my $fh (@ready) {
            my $client = $server->accept();
            my $req = <$client>;
            next unless defined $req;
            
            while(my $h = <$client>) {
                $h =~ s/\r?\n$//;
                last if $h eq '';
            }
            
            my $res_body = "";
            my $res_type = "text/plain";
            
            if ($req =~ /^GET \/ /) {
                my $html_path = dirname($0) . "/debugger.html";
                if (open my $fh_html, '<', $html_path) {
                    local $/ = undef;
                    $res_body = <$fh_html>;
                    close $fh_html;
                    $res_type = "text/html";
                }
            } elsif ($req =~ /^GET \/tests /) {
                my @tests = bsd_glob("tests/*.v");
                my @arr;
                foreach my $t (@tests) {
                    push @arr, sprintf('{"name":"%s"}', $t);
                }
                $res_body = '{"current":"' . $current_tb . '", "tests":[' . join(",", @arr) . ']}';
                $res_type = "application/json";
            } elsif ($req =~ /^GET \/state /) {
                my $cpus_json = join(", ", map {
                    my $st = $cpu_state{$_};
                    my @bps = keys %{$breakpoints{$_} // {}};
                    my $bps_json = "[" . join(",", map { "\"$_\"" } @bps) . "]";
                    sprintf '"%s": {"time":%d, "pc":"%s", "op":"%s", "acc":"%s", "b":"%s", "r2":"%s", "r3":"%s", "r4":"%s", "c":"%s", "z":"%s", "pin_dir":"%s", "pin_out":"%s", "breakpoints": %s}',
                        $_, $st->{time}, $st->{pc}, $st->{op}, $st->{acc}, $st->{b}, $st->{r2}, $st->{r3}, $st->{r4}, $st->{c}, $st->{z}, $st->{pin_dir}, $st->{pin_out}, $bps_json
                } keys %cpu_state);
                my $state_str = $paused ? 'true' : 'false';
                $state_str = 'true' if $sim_finished;
                $res_body = sprintf '{"paused": %s, "cpus": {%s}}', $state_str, $cpus_json;
                $res_type = "application/json";
            } elsif ($req =~ /^GET \/source\?cpu=(\d+) /) {
                my $id = $1;
                my $json = "[]";
                if (exists $asm_source{$id}) {
                    my @arr;
                    foreach my $line (@{$asm_source{$id}}) {
                        my $t = $line->{text};
                        $t =~ s/\\/\\\\/g;
                        $t =~ s/"/\\"/g;
                        push @arr, sprintf('{"pc":"%s", "text":"%s"}', $line->{pc}, $t);
                    }
                    $json = "[" . join(", ", @arr) . "]";
                }
                $res_body = $json;
                $res_type = "application/json";
            } elsif ($req =~ /^POST \/command\?cmd=load_tb&tb=([^& ]+)/) {
                my $tb = $1;
                $tb =~ s/%2F/\//g;
                run_tb($tb);
                $res_body = '{"status":"ok"}';
                $res_type = "application/json";
            } elsif ($req =~ /^POST \/command\?cmd=toggle_bp&cpu=(\d+)&pc=([0-9a-fA-F]+)/) {
                my ($id, $pc_val) = ($1, uc($2));
                if ($breakpoints{$id}{$pc_val}) {
                    delete $breakpoints{$id}{$pc_val};
                } else {
                    $breakpoints{$id}{$pc_val} = 1;
                }
                $res_body = '{"status":"ok"}';
                $res_type = "application/json";
            } elsif ($req =~ /^POST \/command\?cmd=(\w+)/) {
                my $cmd = $1;
                if (!$sim_finished) {
                    if ($cmd eq 'step') {
                        $step_count = 1;
                        $paused = 1;
                    } elsif ($cmd eq 'step10') {
                        $step_count = 10;
                        $paused = 1;
                    } elsif ($cmd eq 'play') {
                        $paused = 0;
                        $step_count = 0;
                    } elsif ($cmd eq 'pause') {
                        $paused = 1;
                        $step_count = 0;
                    }
                }
                $res_body = '{"status":"ok"}';
                $res_type = "application/json";
            }
            
            my $res = "HTTP/1.1 200 OK\r\n";
            $res .= "Content-Type: $res_type\r\n";
            $res .= "Cache-Control: no-store, no-cache, must-revalidate, max-age=0\r\n";
            $res .= "Content-Length: " . length($res_body) . "\r\n";
            $res .= "Connection: close\r\n\r\n";
            $res .= $res_body;
            
            print $client $res;
            close $client;
        }
    }
    
    if (!$sim_finished && (!$paused || $step_count > 0)) {
        while (my $line = <$log_fh>) {
            chomp $line;
            if ($line =~ /^DBG\|(\d+)\|(\d+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\|([^\|]+)/) {
                my ($id, $time, $pc, $op, $acc, $b, $r2, $r3, $r4, $flags, $c, $z, $pin_dir, $pin_out) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14);
                
                # Format to pad if single digit, except for time and xx
                $pc = sprintf("%02x", hex($pc)) if $pc =~ /^[0-9a-fA-F]+$/;
                $cpu_state{$id} = {
                    time => $time, pc => $pc, op => $op, acc => $acc, b => $b, r2 => $r2, r3 => $r3, r4 => $r4,
                    flags => $flags, c => $c, z => $z, pin_dir => $pin_dir, pin_out => $pin_out
                };
                
                if (!$paused && $breakpoints{$id}{uc($pc)}) {
                    $paused = 1;
                    $step_count = 0;
                    last;
                }
                
                if ($paused || $step_count > 0) {
                    if ($step_count > 0) {
                        $step_count--;
                    }
                    last if ($paused || $step_count == 0);
                }
            }
        }
        
        if (eof($log_fh)) {
            $sim_finished = 1;
            $paused = 1;
        }
    }
}
