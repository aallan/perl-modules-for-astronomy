f95 -gline -c -C define_star.f90 radec2rad.f90 cluster_match_subs.f90 corlate.f90
rm libCorlate.a
ar -r libCorlate.a *.o
f95 -gline -o driver driver.f90 libCorlate.a
