  module define_star

    implicit none

    integer, parameter :: mcol=10

    type a_colour
      real :: data
      real :: err
      character(len=2) :: flg
    end type a_colour
  
    type a_star
      integer :: field, id, ccd
      integer :: ra_h, ra_m
      real :: ra_s
      integer :: dc_d, dc_m
      real :: dc_s
      ! At the moment the rule is that if a declination is negative one of
      ! the above three should be set negative.  Eventually it will all be
      ! done via this variable.
      character(len=1) :: dc_sign
      real :: x, y
      type(a_colour), dimension(mcol) :: col
    end type a_star

    interface zero_star
      
      module procedure zero_star_one
      module procedure zero_star_array

    end interface

    contains

    subroutine write_star(iunit, star, ncol)
      
      ! Writes out a star.  If any of the dc_d, dc_m or dc_s are negative 
      ! the declination is written out with a minus sign.
      ! Otherwise its given a plus sign.
      ! Eventually this code will use dc_sign, but at the moment not enough
      ! code sets it for its value to be reliable.

      integer, intent(in) :: iunit
      type(a_star), intent(in) :: star
      integer, optional :: ncol

      integer :: icol, jcol
      real :: xpos, ypos
      character(len=1) :: sign
      
      jcol=mcol
      if (present(ncol)) jcol=ncol

      xpos=star%x
      ypos=star%y
      if (xpos<-9999.99 .or. xpos>99999.99 &
     .or. ypos<-9999.99 .or. ypos>99999.99) then
        xpos=0.0
        ypos=0.0
      end if
      
      sign='+'
      if (star%dc_d < 0) sign='-'
      if (star%dc_m < 0) sign='-'
      if (star%dc_s < 0.0) sign='-'
      if (star%dc_sign == '-') sign='-'
      
      if (star%id>999999 .or. star%id<-99999) then
        print*, 'Format statement cannot cope as star%id is ', star%id
      end if
      
      write(iunit,10) star%field+real(star%ccd)/100.0, star%id, star%ra_h, &
      star%ra_m, star%ra_s, sign, abs(star%dc_d), abs(star%dc_m), &
      abs(star%dc_s), xpos, ypos, (star%col(icol),icol=1,jcol)
      
 10   format(1x,f6.2,2x,i6,2x,i2.2,1x,i2.2,1x,f6.3,1x, &
                         a1,i2.2,1x,i2.2,1x,f5.2,2x, &
      2(f9.3,2x),4(f9.3,2x,f9.3,2x,a2))
      
    end subroutine write_star

    integer function read_star(iunit, star, ncol, string)

      integer, intent(in) :: iunit
      type(a_star), intent(inout) :: star
      integer, optional :: ncol
      character(len=*), optional :: string

      integer :: icol, jcol, iostat
      character(len=4) :: dc_d
      real :: field_ccd

      jcol=mcol
      if (present(ncol)) jcol=ncol

      if (present(string)) then
        read(string,*, iostat=iostat) field_ccd, star%id, star%ra_h, &
        star%ra_m, star%ra_s, dc_d, star%dc_m, star%dc_s, star%x, &
        star%y, (star%col(icol),icol=1,jcol)
      else
        read(iunit,*, iostat=iostat) field_ccd, star%id, star%ra_h, &
        star%ra_m, star%ra_s, dc_d, star%dc_m, star%dc_s, star%x, &
        star%y, (star%col(icol),icol=1,jcol)
      end if
      
      if (iostat == 0) then
        
        if (jcol < mcol) then
          do icol=jcol+1, mcol
            star%col(icol)%data=0.0
            star%col(icol)%err=0.0
            star%col(icol)%flg='AA'
          end do
        end if

        ! Sort out the field and ccd numbers.
        star%field=int(field_ccd)
        if (100*star%field - nint(100.0*field_ccd) == 0) then
          star%ccd=0
        else
          star%ccd=nint(100.0*(field_ccd-real(star%field)))
        end if
      
        read(dc_d,*) star%dc_d
      
        ! Now find all the ways a negative sign declination could have been set.
        star%dc_sign='+'
        if (star%dc_d < 0) star%dc_sign='-'
        if (star%dc_m < 0) star%dc_sign='-'
        if (star%dc_s < 0.0) star%dc_sign='-'
        if (dc_d(1:1) == '-') star%dc_sign='-'
      
        ! When all cluster programs flag negative declination through 
        ! star%dc_sign, we won't need this bit.
        if (star%dc_sign == '-') then
          star%dc_d=-1*abs(star%dc_d)
          star%dc_m=-1*abs(star%dc_m)
          star%dc_s=-1.0*abs(star%dc_s)
        end if

        ! Convert from old-style flags.
        do icol=1, ncol
          if (star%col(icol)%flg(2:2) == ' ') then
            star%col(icol)%flg(2:2)=star%col(icol)%flg(1:1)
            star%col(icol)%flg(1:1)='O'
          end if
          call flagconv(star%col(icol)%flg)
        end do
      end if

      read_star=iostat

    end function read_star

    subroutine zero_star_array(star)

      type(a_star), intent(inout), dimension(:) :: star

      integer :: icol

      star%field=0
      star%ccd=0
      star%id=0
      star%ra_h=0
      star%ra_m=0
      star%ra_s=0.0
      star%dc_d=0
      star%dc_m=0
      star%dc_s=0.0
      star%x=0.0
      star%y=0.0
      do icol=1, mcol
        star%col(icol)%data=0.0
        star%col(icol)%err=0.0
        star%col(icol)%flg='AA'
      end do
    
    end subroutine zero_star_array


    subroutine zero_star_one(star)

      type(a_star), intent(inout) :: star

      integer :: icol

      star%field=0
      star%ccd=0
      star%id=0
      star%ra_h=0
      star%ra_m=0
      star%ra_s=0.0
      star%dc_d=0
      star%dc_m=0
      star%dc_s=0.0
      star%x=0.0
      star%y=0.0
      do icol=1, mcol
        star%col(icol)%data=0.0
        star%col(icol)%err=0.0
        star%col(icol)%flg='AA'
      end do
    
    end subroutine zero_star_one

    subroutine flux_to_mag(star)

      type(a_star), intent(inout) :: star
      
      real :: flux, ferr, tinyflux

      ! The smallest absolute value of the flux that we can represent in 
      ! in magnitude space.  (If its negative it uses the M flag.) We never 
      ! want a magnitude as faint as 100th (since it will overrun our format 
      ! statements), which implies a flux greater than 10**-100/2.5. Nor do 
      ! we want a flux so near zero that when we take the log of it we get a 
      ! floating point error.
      tinyflux=max(100.0*tiny(1.0), 1.0e-40)
    
      flux=star%col(1)%data
      ferr=star%col(1)%err
      if (flux > tinyflux) then
        star%col(1)%data=-2.5*log10(flux)
        star%col(1)%err= 2.5*log10((ferr+flux)/flux)
      else
        flux=abs(flux)
        flux=max(tinyflux, flux)
        ferr=max(tinyflux, ferr)
        star%col(1)%err = 2.5*log10(flux)
        star%col(1)%data=-2.5*log10(ferr)
        if (star%col(1)%flg == 'OO') star%col(1)%flg='OM'
      end if

    end subroutine flux_to_mag


    subroutine mag_to_flux(star)

      type(a_star), intent(inout) :: star
      
      real :: mag, err
    
      mag=star%col(1)%data
      err=star%col(1)%err
      if (star%col(1)%flg == 'OM') then
        star%col(1)%data=-10.0**(err/2.5)
        star%col(1)%err=  10.0**(-mag/2.5)
      else
        star%col(1)%data=10.0**(-mag/2.5)
        ! Evaluating it this way avoids foloating point overflows
        ! if err and mag are both large.  Such a condition happens
        ! when the flux is small.
        star%col(1)%err= 10.0**((err-mag)/2.5) - star%col(1)%data
      end if

    end subroutine mag_to_flux

    subroutine flagconv(aflag)

      ! Converts the old numerical flags into the new character ones,
      ! assuming the old flags have been read as characters.

      character(len=2), intent(inout) :: aflag

      character, dimension(0:9) :: convert=(/'O', 'N', 'E', 'B', 'S', &
      'I', 'V', 'A', 'F', 'M'/)
      integer :: i, ichr
      character :: test

      do ichr=1, 2
        do i=0, 9
          write(test,'(i1)') i
          if (aflag(ichr:ichr) == test) aflag(ichr:ichr)=convert(i)
        end do
      end do

    end subroutine flagconv

    subroutine sort_star(star, nstars, sort)

      type(a_star), dimension(:), intent(inout) :: star
      integer, intent(in) :: nstars
      character(len=*), intent(in) :: sort
      
      integer :: k, l, m
      type(a_star) :: swap

      if (sort /= 'increasing_col(1)%data') then
        print*, 'Error in s/r sort.'
        stop
      end if
      
      do 140 k=2, nstars
        swap=star(k)
        do l=1, k-1
          if (swap%col(1)%data < star(l)%col(1)%data) then
            do m=k, l+1, -1
              star(m)=star(m-1)
            end do
            star(l)=swap
            if (k == nstars) goto 150 
            goto 140
          end if
        end do
140   continue

150   end subroutine sort_star


  end module define_star


