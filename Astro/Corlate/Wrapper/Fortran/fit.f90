    subroutine fit(x, y, sig, a, b, chi2)

      implicit none

      real, dimension(:), intent(in):: x, y, sig
      real, intent(out) :: a, b, chi2
      real :: sigdat, ss, sx, sxoss, sy, st2

      ss=sum(1.0/sig**2.0)
      sx=sum(x/sig**2.0)
      sy=sum(y/sig**2.0)

      sxoss=sx/ss
      b=sum(y*(x-sxoss)/sig**2.0)
      st2=sum(((x-sxoss)/sig)**2.0)
      b=b/st2
      a=(sy-sx*b)/ss

      chi2=sum( ((y-a-b*x)/sig)**2.0 )

    end subroutine fit

