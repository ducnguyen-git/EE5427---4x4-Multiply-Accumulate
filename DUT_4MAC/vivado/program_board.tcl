# Program the Nexys A7-100T SRAM with the existing compute-unit bitstream.
set source_dir [file normalize [file join [file dirname [info script]] ..]]
set bitstream [file join $source_dir build compute_unit compute_unit.bit]
if {![file isfile $bitstream]} {
    error "Bitstream not found: $bitstream. Run vivado/compute_unit.tcl first."
}

open_hw_manager
try {
    connect_hw_server
    set targets [get_hw_targets]
    if {[llength $targets] != 1} {
        error "Expected one connected JTAG target; found [llength $targets]. Connect only the Nexys A7."
    }
    open_hw_target [lindex $targets 0]
    set devices [get_hw_devices -filter {PART =~ xc7a100t*}]
    if {[llength $devices] != 1} {
        error "Expected one xc7a100t FPGA for the Nexys A7-100T; found [llength $devices]."
    }
    set device [lindex $devices 0]
    set_property PROGRAM.FILE $bitstream $device
    program_hw_devices $device
    puts "Programmed Nexys A7-100T. Press CPU RESET before sending UART commands."
} finally {
    close_hw_manager
}
