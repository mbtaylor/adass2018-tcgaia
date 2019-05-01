# adass2018-tcgaia

This repository contains the source code for Mark Taylor's
poster contribution "TOPCAT and Gaia" to the ADASS 2018 conference.

It contains LaTeX source code, a makefile, and graphics files for
some of the figures.  More interestingly, the makefile also contains
all the commands needed to generate some of the other figures:

1. STILTS commands to download required data from VO services
2. STILTS commands to turn those data files into graphics files

This repository is provided in the interests of transparency,
and also as an example of the things that you can do with STILTS.

## gaia_source FITS file

The entire Gaia DR2 source catalogue in various forms,
including the column-oriented FITS file `gaia_source.colfits`
mentioned in the makefile and used to generate the all-sky image
in the Scalability section, is available from
<http://andromeda.star.bris.ac.uk/gaia-dr2/gaia_source/>.
But it's 800Gb!  If you want to try to download it you can, but it is
likely to take a day or more, and I reserve the right to kill the
download if it overburdens the web server (my desktop machine).
It might be a good idea to talk to me first (m.b.taylor@bristol.ac.uk)
if you're planning to attempt a download.


