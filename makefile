
# This is the makefile used to build the poster "TOPCAT and Gaia"
# by Mark Taylor, presented at the ADASS conference 2018.
#
# You can use it at home to build the poster (make build).
# This will download the data required from Gaia VO services,
# then run STILTS commands to generate the figures.
# There are 7 generated figures; the others are TOPCAT screenshots
# or fluff.
#
# Note however that some of the downloaded data files are quite large;
# in total about 400Mb, so you should have reasonable network bandwidth
# before you attempt it.  It wouldn't be hard to get similar figures
# with smaller data files by placing some restrictions on the queries.

##################################################################
# Configuration.

POSTER = poster
STILTS_JAR = stilts.jar
JAVA = java
PDFLATEX = pdflatex

# The stilts command required to generate the data and figures.
# This poster was developed with STILTS v3.1-5; later versions should
# probably work, but if you suspect there's a version issue, you could
# try getting a the relevant version from the old version archive at
# ftp://andromeda.star.bris.ac.uk/pub/star/stilts/ or maybe github.
STILTS = $(JAVA) -Xmx2G -jar $(STILTS_JAR)

BUILT_FIGURES = hyades_uvw.pdf \
                bp_rp.pdf \
                hrd.pdf \
                m4.pdf \
                nobs.pdf \
                uwe.pdf \
                lmc.pdf

BUILT_DATA = 100pc-rv.fits \
             100pc-phot.fits \
             m4.vot \
             lmc-16m.fits \
             gaia-dr2-stats-hpx9.fits \

##################################################################
# Public targets

build: $(POSTER).pdf

data: $(STILTS_JAR) $(BUILT_DATA)

figures: $(STILTS_JAR) $(BUILT_FIGURES)

view: $(POSTER).view

clean:
	rm -f $(POSTER).{aux,log,pdf} a0header.ps sha1.tex

cleanfigures:
	rm -f $(BUILT_FIGURES)

cleandata:
	rm -f $(BUILT_DATA)

cleanstilts:
	rm -f stilts.jar

veryclean: clean cleanfigures cleandata cleanstilts


##################################################################
# Internal targets

.SUFFIXES: .tex .pdf .view

$(POSTER).pdf: $(POSTER).tex $(STILTS_JAR) $(BUILT_FIGURES)
	git show -s --pretty=format:%h >sha1.tex
	$(PDFLATEX) $< \
     || rm $@

# Required version 3.1-4+ currently only available in pre-release.
stilts.jar:
	curl ftp://andromeda.star.bris.ac.uk/pub/star/stilts/pre/stilts.jar >$@

uwe_blank.png:
	convert -size 680x600 canvas:white $@

.pdf.view:
	test -f $< && acroread -geometry +50+50 -openInNewWindow $<

##################################################################
# Data targets

# TAP query for 5+1 astrometric parameters of rows in gaia_source that
# have non-blank radial_velocity.  The result is fairly small, so
# a synchronous query ought to be OK.
100pc-rv.fits:
	$(STILTS) -bench \
                  tapquery \
                  tapurl=http://gea.esac.esa.int/tap-server/tap \
                  adql="SELECT ra, dec, parallax, pmra, pmdec, radial_velocity \
                        FROM gaiadr2.gaia_source \
                        WHERE parallax > 10 AND parallax_over_error > 5 \
                          AND radial_velocity IS NOT NULL" \
                  sync=true \
                  out=$@

# TAP query for sources with good photometry within 100 parsec.
# The result in this case is a bit bigger, so the query will take longer,
# so we execute it asynchronously to avoid hitting the timeout.
100pc-phot.fits:
	$(STILTS) -bench \
                  tapquery \
                  tapurl=http://gea.esac.esa.int/tap-server/tap \
                  adql="SELECT parallax, phot_g_mean_mag, bp_rp, \
                               astrometric_excess_noise, \
                               astrometric_chi2_al, astrometric_n_good_obs_al \
                        FROM gaiadr2.gaia_source \
                        WHERE parallax > 10 \
                          AND parallax_over_error > 10 \
                          AND phot_bp_mean_flux_over_error > 10 \
                          AND phot_rp_mean_flux_over_error > 10" \
                  out=$@

# Cone search of objects within 0.3 degrees of the center of Messier 4.
# You could do this using a TAP query, but in this case we access
# the cone search service directly.
m4.vot:
	curl 'http://gaia.ari.uni-heidelberg.de/cone/search?RA=245.89675&DEC=-26.52575&SR=0.3&VERB=1' \
             >$@
 
# This file contains positions and parallaxes for all the sources within
# 3.5 degrees of the LMC - about 16 million of them.  Since there are
# so many, the ESA TAP service will refuse to provide the result.
# We use instead the GAVO-DC service at ARI Heidelberg, which contains
# a stripped-down version of the source catalogue, and will serve
# queries up to 16 million rows.  We have to use aynchronous query mode,
# otherwise this too will time out.  This query may take a while;
# 5 minutes or so if it starts executing right away, or quite a bit more
# if the service is busy and the job gets queued for later execution.
lmc-16m.fits:
	$(STILTS) -bench \
                  tapquery \
                  tapurl=http://dc.g-vo.org/tap \
                  sync=false \
                  delete=always \
                  maxrec=16000000 \
                  adql="SELECT ra, dec, parallax \
                        FROM gaia.dr2light \
                        WHERE 1=CONTAINS(POINT('', ra, dec), \
                                         CIRCLE('', 81, -69.5, 3.5))" \
                  ocmd=progress \
                  out=$@

# This file was generated by downloading the entire gaia-source catalogue
# in CSV form, turning it into a huge FITS file, and running tskymap on
# the result, like this:
#     stilts tskymap in=gaia_source.colfits icmd=progress \
#                    tiling=hpx9 lon=ra lat=dec combine=mean \
#                    count=true cols=bp_rp \
#                    out=gaia-dr2-stats-hpx9.fits
# The download is however a very expensive operation, so not reproduced here.
# Instead, we copy a version prepared earlier.
# This HEALPix file is still quite big: 75Mb.
gaia-dr2-stats-hpx9.fits:
	curl 'http://andromeda.star.bris.ac.uk/data/$@' >$@



##################################################################
# Figure targets

hyades_uvw.pdf: 100pc-rv.fits
	$(STILTS) plot2cube \
                  in=100pc-rv.fits \
                  icmd='addcol -shape 3 gal_uvw icrsToGal(astromUVW(ra,dec,pmra,pmdec,radial_velocity,1000./parallax,false))' \
                  xpix=500 ypix=450 insets=-60,0,-40,0 \
                  xcrowd=0.6 ycrowd=0.6 zcrowd=0.6 \
                  xmin=-70 xmax=-3 ymin=-33.5 ymax=33.5 zmin=-38.1 zmax=28.9 \
                  phi=163.63 theta=21.5 psi=164.78 \
                  layer1=mark size1=3 \
                  shading1=density \
                  densemap1=cubehelix densefunc1=sqrt denseclip=0.063,1 \
                  x1='gal_uvw[0]' xlabel='U / km/s' \
                  y1='gal_uvw[1]' ylabel='V / km/s' \
                  z1='gal_uvw[2]' zlabel='W / km/s' \
                  out=$@

bp_rp.pdf: gaia-dr2-stats-hpx9.fits
	$(STILTS) plot2sky \
                  projection=aitoff datasys1=equatorial \
                  grid=false labelpos=none \
                  viewsys=galactic \
                  insets=0,-40,10,540 xpix=4600 ypix=2000 \
                  fontsize=112 texttype=latex auxwidth=64 \
                  layer1=healpix in1=gaia-dr2-stats-hpx9.fits \
                  healpix1=hpx9 value1=bp_rp \
                  degrade1=0 datalevel1=9 combine1=mean \
                  auxmap=pastel auxclip=0,1 auxfunc=linear \
                  auxmin=0.96 auxmax=3.1 \
                  auxlabel='median BP-RP / mag' \
                  out=$@

hrd.pdf: 100pc-phot.fits
	$(STILTS) plot2plane \
                  in=100pc-phot.fits \
                  layer1=mark shading1=weighted \
                  x1=bp_rp y1='phot_g_mean_mag+5*log10(parallax/10)' \
                  weight1=astrometric_excess_noise \
                  auxmap=gnuplot2 auxflip=true auxfunc=log \
                  auxclip=0,1 auxquant=9 \
                  yflip=true \
                  out=$@

m4.pdf: m4.vot
	$(STILTS) plot2plane \
                  grid=true \
                  texttype=latex fontsize=24 \
                  xmin=-25.7 xmax=13 ymin=-27.8 ymax=8.2 \
                  in=m4.vot \
                  x=pmra y=pmdec \
                  size=3 \
                  layer1=mark color1=red \
                  layer2=mark color2=blue \
                  icmd2='select isInside(pmra,pmdec,-12.3,-11.9,-7.1,-14.1,-5.3,-18.0,-5.8,-22.6,-9.3,-25.8,-16.6,-25.3,-20.7,-22.2,-21.3,-18.1,-18.8,-13.5,-15.1,-11.8)' \
                  xpix=700 ypix=700 \
                  leglabel1=background leglabel2=cluster \
                  xlabel='\mu_\alpha*' ylabel='\mu_\delta' \
                  legpos=0.9,0.1 \
                  out=$@

nobs.pdf: gaia-dr2-stats-hpx9.fits
	$(STILTS) $(STILTS_MEM_FLAGS) \
                  plot2sky \
                  projection=aitoff datasys1=equatorial \
                  grid=false labelpos=none \
                  viewsys=galactic \
                  insets=0,0,0,0 xpix=4000 ypix=2000 \
                  auxvisible=false \
                  layer1=healpix in1=gaia-dr2-stats-hpx9.fits \
                  healpix1=hpx9 value1=astrometric_n_obs_al \
                  degrade1=0 datalevel1=9 combine1=median \
                  auxmap=viridis auxclip=0,1 auxfunc=log \
                  auxmin=60 auxmax=900 \
                  layer2=skygrid gridsys2=ecliptic gridcolor2=black \
                  out=$@

uwe.pdf: 100pc-phot.fits
	$(STILTS) plot2plane \
                  ylog=true texttype=latex fontsize=24 \
                  in1=100pc-phot.fits \
                  icmd1='addcol UWE sqrt(astrometric_chi2_al/(astrometric_n_good_obs_al-5))' \
                  x1=phot_g_mean_mag y1=uwe \
                  layer1a=mark \
                     color1a=d0d0d0 shading1a=density denseclip1a=0,0.85 \
                  layer1b=contour \
                     color1b=00ffcc zero1b=0.2 smooth1b=8 \
                  layer1c=quantile \
                     color1c=yellow transparency1c=0.6 smooth1c=0.15 \
                     thick1c=3 quantiles1c=0.25,0.75 \
                  layer1d=quantile \
                     color1d=yellow smooth1d=0.2 \
                     thick1d=4 quantiles1d=0.5 \
                  layer2=function \
                     xname2=G fexpr2='1.2*max(1,exp(-0.2*(G-19.5)))' \
                  color2=red thick2=4 antialias2=true \
                  xlabel="G" \
                  ylabel="\sqrt{\chi^2 / \nu}" \
                  leglabel2='1.2 \max[1,\ e^{-0.2(G-19.5)}]' \
                  legseq=2 legend=true legpos=0.9,0.9 \
                  minor=false xcrowd=0.5 ycrowd=0.5 \
                  xpix=680 ypix=600 \
                  out=$@

lmc.pdf: lmc-16m.fits
	$(STILTS) $(STILTS_MEM_FLAGS) \
                  plot2sky sex=false \
                  auxmap=hotcold auxmin=-0.1 auxmax=+0.1 \
                  auxvisible=true auxlabel='median parallax / mas' \
                  in1=lmc-16m.fits \
                  icmd1=progress \
                  layer1=mark lon1=ra lat1=dec weight1=parallax \
                              shading1=weighted combine1=median \
                  clon=81 clat=-69.5 radius=3.45 \
                  out=$@


