// RUN: circt-opt --llhd-lower-processes %s | FileCheck %s

// Lower one-shot processes with Sim prints to initial blocks.

// CHECK-LABEL: @OneShotSimPrint
// CHECK-NOT: llhd.process
// CHECK: sv.initial {
// CHECK-NEXT: sim.fmt.literal "hello\0A"
// CHECK-NEXT: sim.proc.print
// CHECK: hw.output
hw.module @OneShotSimPrint() {
  llhd.process {
    %0 = sim.fmt.literal "hello\0A"
    sim.proc.print %0
    llhd.halt
  }
  hw.output
}

// Preserve SV prints as well.

// CHECK-LABEL: @OneShotSVPrint
// CHECK-NOT: llhd.process
// CHECK: sv.initial {
// CHECK-NEXT: sv.write "hello\0A"
// CHECK: hw.output
hw.module @OneShotSVPrint() {
  llhd.process {
    sv.write "hello\0A"
    llhd.halt
  }
  hw.output
}

// Forward results defined outside the process.

// CHECK-LABEL: @OneShotResultsFromOutside
// CHECK-NOT: llhd.process
// CHECK: sv.initial {
// CHECK: llhd.assign {{%.+}}, %c16_i32 if %true
hw.module @OneShotResultsFromOutside() {
  %c0_i32 = hw.constant 0 : i32
  %c16_i32 = hw.constant 16 : i32
  %true = hw.constant true
  %i = llhd.sig %c0_i32 : <i32>
  %0:2 = llhd.process -> i32, i1 {
    %1 = sim.fmt.literal "config\0A"
    sim.proc.print %1
    llhd.halt %c16_i32, %true : i32, i1
  }
  llhd.assign %i, %0#0 if %0#1 : i32
  hw.output
}

// Eliminate empty one-shot processes.

// CHECK-LABEL: @EmptyOneShotIsDropped
// CHECK-NOT: llhd.process
// CHECK-NOT: sv.initial
// CHECK: hw.output
hw.module @EmptyOneShotIsDropped() {
  llhd.process {
    llhd.halt
  }
  hw.output
}

// Do not lower processes with signal drives to initial blocks.

// CHECK-LABEL: @OneShotDriveStays
// CHECK: llhd.process
// CHECK-NOT: sv.initial
hw.module @OneShotDriveStays(in %a : i1) {
  %false = hw.constant false
  %s = llhd.sig %false : <i1>
  %t = llhd.constant_time <0ns, 1d>
  llhd.process {
    %0 = sim.fmt.literal "hello\0A"
    sim.proc.print %0
    llhd.drv %s, %a after %t : i1
    llhd.halt
  }
  hw.output
}
