   ! Driver program for corlate() subroutine.
   !
   
   program driver

      use corlate_subs
      use f90_unix_env

      implicit none
      
      ! File names
      character(len=50) :: file_name_1
      character(len=50) :: file_name_2
      character(len=50) :: file_name_3
      character(len=50) :: file_name_4
      character(len=50) :: file_name_5
      character(len=50) :: file_name_6
      character(len=50) :: file_name_7
      character(len=50) :: file_name_8
      
      ! Return STATUS
      !    0 = success
      !   -1 = failed to open file_name_1
      !   -2 = failed to open file_name_2
      !   -3 = Too few stars paired between catalogues.
      !   -4 = Incorrect command line arguements
      integer :: status

      if ( iargc() .ne. 8) then
         status = -4
         write(*,*) 'Status: ', status
         stop
      else
         call getarg(1,file_name_1)
         call getarg(2,file_name_2)
         call getarg(3,file_name_3)
         call getarg(4,file_name_4)
         call getarg(5,file_name_5)
         call getarg(6,file_name_6)
         call getarg(7,file_name_7)
         call getarg(8,file_name_8)
      endif
                    
      status = corlate( file_name_1, file_name_2, file_name_3, &
                        file_name_4, file_name_5, file_name_6, &
                        file_name_7, file_name_8 )

      write(*,*) 'Status: ', status

    end program driver
