/* eSTAR IO header file -*- mode: Fundamental;-*-
 * $Headers$
 */
#ifndef ESTAR_IO_H
#define ESTAR_IO_H
/* external variables */
extern int eSTAR_IO_Error_Number;
extern char eSTAR_IO_Error_String[];

/* external functions */
extern int eSTAR_IO_Open_Client(char *hostname,int port,globus_io_handle_t *handle);
extern int eSTAR_IO_Close_Client(globus_io_handle_t *handle);
extern int eSTAR_IO_Start_Server(unsigned short *port,
	void (*connection_callback)(globus_io_handle_t *connection_handle));
extern int eSTAR_IO_Close_Server(void);
extern int eSTAR_IO_Write_Message(globus_io_handle_t *handle,char *message);
extern int eSTAR_IO_Write_Binary_Message(globus_io_handle_t *handle,void *data_buffer,size_t data_buffer_length);
extern int eSTAR_IO_Read_Message(globus_io_handle_t *handle,char **message);
extern void eSTAR_IO_Error(void);
/*
** $Log: estar_io.h,v $
** Revision 1.1  2002/03/04 23:29:22  aa
** Inital XS framework for eSTAR::IO library
**
** Revision 1.2  2002/01/27 13:56:14  cjm
** Added eSTAR_IO_Write_Binary_Message.
**
** Revision 1.1  2001/12/21 16:21:48  cjm
** Initial revision
**
*/
#endif
