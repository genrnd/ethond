reg16
=====

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

BUILDING
--------

  This program is built using autotools.

    autoreconf -fiv
    ./configure
    make && make install

  See documentation for autotools for details.

AUTHORS
-------

  STC Metrotek System Team <systeam@metrotek.spb.ru>

COPYRIGHT
---------

  STC Metrotek 2016. All rights reserved.

DATE
----

  Wed, 05 Oct 2016 16:57:32 +0300

