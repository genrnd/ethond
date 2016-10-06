reg16(1) -- read/write SoC Cyclone V FPGA registers.
====================================================

SYNOPSIS
--------

    reg16 REG [WRITE_DATA]

DESCRIPTION
-----------

This utility reads and writes system memory addresses mapped on FPGA registers
space. The H2F bus address is hardcoded to match CycloneV-based devices'
mapping.

The utility deals with 16-bit registers, accepting an index of such a register
and printing its contents or writing to it if the data to be written is
specified.

REG add WRITE_DATA values must be specified in hex format with range from 0x0 to
0xffff.

For example:

  * `reg16 0xaaff` -- reads value 0xaaff register
  * `reg16 0xaaff 0x4` -- writes value to 0xaaff register

BUILDING
--------

  Fetch sources from https://github.com/STC-Metrotek/ethond/utils.
  Then:
  
  * `cd utils/reg16 && make` to build reg16
  * `cd utils/reg16 && make deb` to create debian package

  Package build requires `ruby-ronn` for converting man page and 
  `debhelper` for creating debian package. 

AUTHORS
-------

  STC Metrotek System Team <systeam@metrotek.spb.ru>

COPYRIGHT
---------

  STC Metrotek 2016. All rights reserved.

DATE
----

  Wed, 05 Oct 2016 16:57:32 +0300

