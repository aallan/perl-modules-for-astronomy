   ! Driver program for corlate() subroutine.
   
   ! This writes out a series of files with new_ in front of the file 
   ! names, which should be compared with the similar files with old_
   ! at the front.  Makes sure you use the LX200 + USNO-A2 parameters
   ! in corlate.

   ! The graph file colfit.grf then allows you a graphical check of the
   ! results.
   
    module driver_subs

    implicit none

    contains

    subroutine file_in(file_name, file)

      character(len=*), intent(in) :: file_name
      character(len=*), allocatable, dimension(:), intent(out) :: file

      integer :: i, line, iostat

      open(unit=1, file=file_name, status='old', action='read')
      line=0
      do
        read(1,*,iostat=iostat)
        if (iostat < 0) exit
        line=line+1
      end do
      rewind(1)
      allocate(file(line))
      do i=1, line
        read(1,'(a120)') file(i)
      end do
      close(1)

    end subroutine file_in

    end module driver_subs

    program driver

      use corlate_subs
      use f90_unix_env
      use driver_subs

      implicit none
      
      ! File names
      character(len=50), parameter :: file_name_1="archive.cat"
      character(len=50), parameter :: file_name_2="new.cat"
      character(len=50), parameter :: file_name_3="new_corlate.log"
      character(len=50), parameter :: file_name_4="new_corlate.cat"
      character(len=50), parameter :: file_name_5="new_colfit.cat"
      character(len=50), parameter :: file_name_6="new_colfit.fit"
      character(len=50), parameter :: file_name_7="new_hist.dat"
      character(len=50), parameter :: file_name_8="new_info.dat"

      character(len=120), dimension(:), allocatable :: file_1, file_2
      
      ! Return STATUS
      !    0 = success
      !   -1 = failed to open file_name_1
      !   -2 = failed to open file_name_2
      !   -3 = Too few stars paired between catalogues.
      integer :: status

      call file_in(file_name_1, file_1)
      call file_in(file_name_2, file_2)

      status = corlate( file_1, file_2, file_name_3, &
                        file_name_4, file_name_5, file_name_6, &
                        file_name_7, file_name_8 )

      write(*,*) 'Status: ', status

    end program driver

