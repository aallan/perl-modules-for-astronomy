/* eSTAR IO source file -*- mode: Fundamental;-*-
 * $Headers$
 */
/**
 * This file contains basic wrappers of globus_io routines, and a simple text message passing protocol.
 * It includes standard error handlers.
 * <b>Note</b> the globus common and io modules should be activated prior to calling these routines as follows:
 * <pre>
 * rc = globus_module_activate(GLOBUS_COMMON_MODULE);
 * rc = globus_module_activate(GLOBUS_IO_MODULE);
 * </pre>
 * <b>Note</b> The server is Multi-threaded. GLOBUS_DEVELOPMENT_PATH must be set for threaded libraries
 * when linking this code, e.g. <pre>$GLOBUS_PATH/globus-development-path -standard -threads -debug -32 -64</pre>
 * <b>Note</b> 
 * @author Chris Mottram
 * @version $Revision: 1.1 $
 */
/**
 * This hash define is needed before including source files give us POSIX.4/IEEE1003.1b-1993 prototypes
 * for time.
 */
#define _POSIX_SOURCE 1
/**
 * This hash define is needed before including source files give us POSIX.4/IEEE1003.1b-1993 prototypes
 * for time.
 */
#define _POSIX_C_SOURCE 199309L
#include <string.h>
#include <time.h>
#include "globus_common.h"
#include "globus_io.h"
#include "estar_io.h"

/* internal hash definition */
/**
 * Length of eSTAR_IO_Error_String.
 * @see #eSTAR_IO_Error_String
 */
#define ESTAR_IO_ERROR_STRING_LENGTH 	(512)
/**
 * Length of the message size are prepended to messages sent over the connection.
 */
#define ESTAR_IO_MESSAGE_SIZE_LENGTH	(sizeof(int))

/* internal enumeration */
/**
 * Enumerated type describing the state of a server connection started in eSTAR_IO_Start_Server.
 * @see #eSTAR_IO_Start_Server
 * @see #Server_State
 */
enum IO_SERVER_STATE
{
	IO_SERVER_STATE_NOT_STARTED=0,IO_SERVER_STATE_RUNNING,
	IO_SERVER_STATE_TERMINATING,IO_SERVER_STATE_TERMINATED
};

/* internal typedefs */
/**
 * Typedef of the connection callback function declaration.
 * This is passed as a parameter when starting a server, and is called internally in each connection thread.
 */
typedef void (*IO_Server_Connection_Callback_T)(globus_io_handle_t *connection_handle);

/* external variables */
/**
 * Internal error variable.
 * @see #eSTAR_IO_Error_String
 */
int eSTAR_IO_Error_Number = 0;
/**
 * Internal error string.
 * @see #eSTAR_IO_Error_Number
 */
char eSTAR_IO_Error_String[ESTAR_IO_ERROR_STRING_LENGTH];

/* internal functions */
static void Get_Current_Time(char *time_string,int string_length);
static void *IO_Server_Connection_Thread(void *user_arg);

/* internal variables */
/**
 * Globus IO server attributes data.
 */
static globus_io_attr_t eSTAR_IO_Globus_IO_Server_Attr;
/**
 * Globus IO client attributes data.
 */
static globus_io_attr_t eSTAR_IO_Globus_IO_Client_Attr;
/**
 * Globus IO Authorization data.
 */
static globus_io_secure_authorization_data_t  eSTAR_IO_Globus_IO_Auth_Data;
/**
 * Globus IO Authorization mode data.
 */
static globus_io_secure_authorization_mode_t  eSTAR_IO_Globus_IO_Auth_Mode;
/**
 * The globus io handle the server listener port is on.
 */
static globus_io_handle_t IO_Server_Listener_Handle;
/**
 * Variable used in eSTAR_IO_Start_Server, to monitor the servers state.
 * @see IO_Server_State;
 */
static enum IO_SERVER_STATE Server_State = IO_SERVER_STATE_NOT_STARTED;
/**
 * Copy of the connection callback parameter passed into eSTAR_IO_Start_Server.
 * @see #eSTAR_IO_Start_Server
 * @see #IO_Server_Connection_Callback_T
 */
static IO_Server_Connection_Callback_T IO_Server_Connection_Callback;

/* -----------------------------------
**  external routines 
** ----------------------------------- */
/**
 * Routine to open a client connection.
 * @param hostname The FQDN of the host to connect to.
 * @param port The port number to connect to.
 * @param handle The address of a globus io handle to save the open connection data into.
 * @return The routine returns GLOBUS_TRUE on success, GLOBUS_FALSE on failure.
 * @see #eSTAR_IO_Globus_IO_Client_Attr
 * @see #eSTAR_IO_Globus_IO_Auth_Data
 * @see #eSTAR_IO_Globus_IO_Auth_Mode
 */
int eSTAR_IO_Open_Client(char *hostname,int port,globus_io_handle_t *handle)
{
	globus_result_t result;
	globus_object_t* globus_error = NULL;
	char *error_string = NULL;

	if(hostname == NULL)
	{
		eSTAR_IO_Error_Number = 11;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Open_Client:hostname was NULL.");
		return GLOBUS_FALSE;
	}
	if(handle == NULL)
	{
		eSTAR_IO_Error_Number = 12;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Open_Client:handle was NULL.");
		return GLOBUS_FALSE;
	}
	globus_io_tcpattr_init(&eSTAR_IO_Globus_IO_Client_Attr);
	globus_io_secure_authorization_data_initialize(&eSTAR_IO_Globus_IO_Auth_Data);
/* use GSI */
	globus_io_attr_set_secure_channel_mode(&eSTAR_IO_Globus_IO_Client_Attr,GLOBUS_IO_SECURE_CHANNEL_MODE_GSI_WRAP);
/* diddly don't lose data
	globus_io_attr_set_socket_linger(&eSTAR_IO_Globus_IO_Client_Attr,GLOBUS_TRUE,5);
	globus_io_attr_set_tcp_nodelay(&eSTAR_IO_Globus_IO_Client_Attr,GLOBUS_TRUE);
*/
/* authentication information */
/* diddly
	globus_io_attr_set_secure_authentication_mode(&eSTAR_IO_Globus_IO_Client_Attr,
		GLOBUS_IO_SECURE_AUTHENTICATION_MODE_GSSAPI,GSS_C_NO_CREDENTIAL);
*/
/* diddly
	eSTAR_IO_Globus_IO_Auth_Mode = GLOBUS_IO_SECURE_AUTHORIZATION_MODE_SELF;
or
	eSTAR_IO_Globus_IO_Auth_Mode = GLOBUS_IO_SECURE_AUTHORIZATION_MODE_IDENTITY;
	globus_io_secure_authorization_data_set_identity(&eSTAR_IO_Globus_IO_Auth_Data,"DN string");
*/
/* diddly
	eSTAR_IO_Globus_IO_Auth_Mode = GLOBUS_IO_SECURE_AUTHORIZATION_MODE_NONE;
	globus_io_attr_set_secure_authorization_mode(&eSTAR_IO_Globus_IO_Client_Attr,eSTAR_IO_Globus_IO_Auth_Mode,&
		eSTAR_IO_Globus_IO_Auth_Data);
*/
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Open_Client:trying to connect to %s:%d\n",hostname,port);
#endif
	result = globus_io_tcp_connect(hostname,(unsigned short)port,&eSTAR_IO_Globus_IO_Client_Attr,handle);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 13;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Open_Client:connect error(%s:%d,%s).",
			hostname,port,error_string);
		return GLOBUS_FALSE;
	}
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Open_Client:connected to %s:%d\n",hostname,port);
#endif
	return GLOBUS_TRUE;
}

/**
 * Close a client connection. Also destroys the tcpattr created in Open_Client.
 * @param handle The address of a globus io handle opened in eSTAR_IO_Open_Client.
 * @return The routine returns GLOBUS_TRUE on success, GLOBUS_FALSE on failure.
 * @see #eSTAR_IO_Open_Client
 * @see #eSTAR_IO_Globus_IO_Client_Attr
 */
int eSTAR_IO_Close_Client(globus_io_handle_t *handle)
{
	globus_result_t result;
	globus_object_t* globus_error = NULL;
	char *error_string = NULL;

	if(handle == NULL)
	{
		eSTAR_IO_Error_Number = 14;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Close_Client:handle was NULL.");
		return GLOBUS_FALSE;
	}
	result = globus_io_close(handle);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 15;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Close_Client:close error(%s).",
			error_string);
		return GLOBUS_FALSE;
	}
	result = globus_io_tcpattr_destroy(&eSTAR_IO_Globus_IO_Client_Attr);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 16;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Close_Client:tcpattr_destroy error(%s).",
			error_string);
		return GLOBUS_FALSE;
	}
	return GLOBUS_TRUE;
}

/**
 * Routine to start a server listening for connections.
 * <b>Note</b> The server is Multi-threaded. GLOBUS_DEVELOPMENT_PATH must be set for threaded libraries
 * when linking this code, e.g. <pre>$GLOBUS_PATH/globus-development-path -standard -threads -debug -32 -64</pre>
 * @param port The address of an integer holding the port number. If the port number is -1 and entry,
 * 	on return it will contain a port number selected by globus_io.
 * @param connection_callback The address of a routine to be called each time a connection is made.
 * 	The routine is passed the globus_io handle of the connection. The routine is called in a newly created
 * 	globus thread.
 * @return The routine returns GLOBUS_TRUE on success, GLOBUS_FALSE on failure.
 * @see #eSTAR_IO_Globus_IO_Server_Attr
 * @see #eSTAR_IO_Globus_IO_Auth_Data
 * @see #eSTAR_IO_Globus_IO_Auth_Mode
 * @see #Server_State
 * @see #IO_Server_Connection_Callback
 */
int eSTAR_IO_Start_Server(unsigned short *port,void (*connection_callback)(globus_io_handle_t *connection_handle))
{
	globus_result_t result;
	globus_object_t* globus_error = NULL;
	globus_io_handle_t connection_handle;
	globus_thread_t new_thread;
	char *error_string = NULL;
	int retval;

	if(port == NULL)
	{
		eSTAR_IO_Error_Number = 17;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Start_Server:port was NULL.");
		return GLOBUS_FALSE;
	}
	if(connection_callback == NULL)
	{
		eSTAR_IO_Error_Number = 19;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Start_Server:connection_callback was NULL.");
		return GLOBUS_FALSE;
	}
	IO_Server_Connection_Callback = connection_callback;
/* initialise */
	globus_io_tcpattr_init(&eSTAR_IO_Globus_IO_Server_Attr);
	globus_io_secure_authorization_data_initialize(&eSTAR_IO_Globus_IO_Auth_Data);
/* use GSI */
	globus_io_attr_set_secure_channel_mode(&eSTAR_IO_Globus_IO_Server_Attr,GLOBUS_IO_SECURE_CHANNEL_MODE_GSI_WRAP);
/* diddly don't lose data
	globus_io_attr_set_socket_linger(&eSTAR_IO_Globus_IO_Server_Attr,GLOBUS_TRUE,5);
	globus_io_attr_set_tcp_nodelay(&eSTAR_IO_Globus_IO_Server_Attr,GLOBUS_TRUE);
*/
/* authentication information */
/* diddly
	globus_io_attr_set_secure_authentication_mode(&eSTAR_IO_Globus_IO_Server_Attr,
		GLOBUS_IO_SECURE_AUTHENTICATION_MODE_GSSAPI,GSS_C_NO_CREDENTIAL);
*/
/* diddly
	eSTAR_IO_Globus_IO_Auth_Mode = GLOBUS_IO_SECURE_AUTHORIZATION_MODE_SELF;
or
	eSTAR_IO_Globus_IO_Auth_Mode = GLOBUS_IO_SECURE_AUTHORIZATION_MODE_IDENTITY;
	globus_io_secure_authorization_data_set_identity(&eSTAR_IO_Globus_IO_Auth_Data,"DN string");
*/
/* diddly
	eSTAR_IO_Globus_IO_Auth_Mode = GLOBUS_IO_SECURE_AUTHORIZATION_MODE_NONE;
	globus_io_attr_set_secure_authorization_mode(&eSTAR_IO_Globus_IO_Server_Attr,eSTAR_IO_Globus_IO_Auth_Mode,&
		eSTAR_IO_Globus_IO_Auth_Data);
*/
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Start_Server:trying to listen on port %hu\n",(*port));
#endif
	result = globus_io_tcp_create_listener(port,5,&eSTAR_IO_Globus_IO_Server_Attr,&IO_Server_Listener_Handle);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 20;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Start_Server:connect error(%hu,%s).",
			(*port),error_string);
		globus_io_tcpattr_destroy(&eSTAR_IO_Globus_IO_Server_Attr);
		return GLOBUS_FALSE;
	}
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Start_Server:listening on port %hu\n",(*port));
#endif
	Server_State = IO_SERVER_STATE_RUNNING;
	while(Server_State == IO_SERVER_STATE_RUNNING)
	{
		result = globus_io_tcp_listen(&IO_Server_Listener_Handle);
		if (result != GLOBUS_SUCCESS)
		{
		/* if quit is set this error was because the server was closed from another thread,
		** whilst the server thread was in globus_io_tcp_listen. */
			if(Server_State == IO_SERVER_STATE_TERMINATING)
				continue;
			else
			{
				globus_error = globus_error_get(result);
				error_string = globus_object_printable_to_string(globus_error);
				eSTAR_IO_Error_Number = 21;
				sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Start_Server:listen failed(%hu,%s).",
					(*port),error_string);
				eSTAR_IO_Error();
				continue;
			}
		}
		result = globus_io_tcp_accept(&IO_Server_Listener_Handle,&eSTAR_IO_Globus_IO_Server_Attr,&connection_handle);
		if(result != GLOBUS_SUCCESS)
		{
			globus_error = globus_error_get(result);
			error_string = globus_object_printable_to_string(globus_error);
			eSTAR_IO_Error_Number = 22;
			sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Start_Server:accept failed(%hu,%s).",
				(*port),error_string);
			eSTAR_IO_Error();
			continue;
		}
#ifdef ESTAR_IO_DEBUG
		globus_libc_printf("eSTAR_IO_Start_Server:connection accepted\n");
#endif
/* create the thread with default attributes */
		retval = globus_thread_create(&new_thread,NULL,IO_Server_Connection_Thread,&connection_handle);
		if(retval != 0)
		{
			eSTAR_IO_Error_Number = 28;
			sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Start_Server:creating thread failed(%d).",
				retval);
			return GLOBUS_FALSE;
		}
#ifdef ESTAR_IO_DEBUG
		globus_libc_printf("eSTAR_IO_Start_Server:started thread\n");
#endif
	}/* end while */
	Server_State=IO_SERVER_STATE_TERMINATED;
	return GLOBUS_TRUE;
}

/**
 * Close a server connection. Also destroys the tcpattr created in start server.
 * @return The routine returns GLOBUS_TRUE on success, GLOBUS_FALSE on failure.
 * @see #eSTAR_IO_Start_Server
 * @see #eSTAR_IO_Globus_IO_Server_Attr
 * @see #Server_State
 */
int eSTAR_IO_Close_Server(void)
{
	globus_result_t result;
	globus_object_t* globus_error = NULL;
	char *error_string = NULL;

	if(Server_State != IO_SERVER_STATE_RUNNING)
	{
		eSTAR_IO_Error_Number = 18;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Close_Server:Illegal Server State(%d).",
			Server_State);
		return GLOBUS_FALSE;
	}
/* set quit before closing handle, so server thread does not throw an error */
	Server_State=IO_SERVER_STATE_TERMINATING;
/* close server listener handle */
	result = globus_io_close(&IO_Server_Listener_Handle);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 26;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Close_Server:close error(%s).",
			error_string);
		return GLOBUS_FALSE;
	}
	result = globus_io_tcpattr_destroy(&eSTAR_IO_Globus_IO_Server_Attr);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 27;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Close_Server:tcpattr_destroy error(%s).",
			error_string);
		return GLOBUS_FALSE;
	}
	return GLOBUS_TRUE;
}

/**
 * Routine to write the text message to a globus_io stream represented by handle.
 * The string is prepended with ESTAR_IO_MESSAGE_SIZE_LENGTH bytes giving it's length, and sent without a terminator.
 * eSTAR_IO_Read_Message will read a mesage sent with this routine.
 * @param handle The address of a globus_io handle opened by a connection being made to a server, or an Open_Client
 * 	call being made.
 * @param message A NULL terminated character string, that should not be NULL.
 * @return The routine returns GLOBUS_TRUE if the message was sent successfully, and GLOBUS_FALSE
 * 	if something failed. eSTAR_IO_Error_Number and eSTAR_IO_Error_String is filled in with the error
 * 	if something failed.
 * @see #eSTAR_IO_Read_Message
 * @see #ESTAR_IO_MESSAGE_SIZE_LENGTH
 */
int eSTAR_IO_Write_Message(globus_io_handle_t *handle,char *message)
{
	globus_byte_t *message_block = NULL;
	globus_result_t result;
	globus_size_t bytes_written;
	globus_object_t* globus_error = NULL;
	char *error_string = NULL;
	globus_size_t message_length;

	if(handle == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 4;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Message:handle was NULL.");
		return GLOBUS_FALSE;
	}
	if(message == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 1;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Message:message was NULL.");
		return GLOBUS_FALSE;
	}
/* allocate message block */
	message_block = globus_libc_malloc((strlen(message)+ESTAR_IO_MESSAGE_SIZE_LENGTH)*sizeof(char));
	if(message_block == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 2;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Message:memory allocation error(%d).",
			(strlen(message)+ESTAR_IO_MESSAGE_SIZE_LENGTH));
		return GLOBUS_FALSE;
	}
/* setup message block */
	message_length = htonl(strlen(message));
	memcpy(message_block,&message_length,ESTAR_IO_MESSAGE_SIZE_LENGTH);
	globus_libc_sprintf(message_block+ESTAR_IO_MESSAGE_SIZE_LENGTH,"%s",message);
/* send message block */
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Write_Message: about to send '%s'.\n",message);
#endif
	result = globus_io_write(handle,message_block,strlen(message)+ESTAR_IO_MESSAGE_SIZE_LENGTH,&bytes_written);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		globus_libc_free(message_block);
		eSTAR_IO_Error_Number = 3;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Message:write error(%s,%d,%d,%s).",
			message,strlen(message_block),bytes_written,error_string);
		return GLOBUS_FALSE;
	}
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Write_Message: sent '%s'.\n",message);
#endif
/* free allocated memory */
	globus_libc_free(message_block);
	return GLOBUS_TRUE;
}

/**
 * Routine to write a binary data message to a globus_io stream represented by handle.
 * The buffer is prepended with ESTAR_IO_MESSAGE_SIZE_LENGTH bytes giving it's length, and sent without a terminator.
 * eSTAR_IO_Read_Message will read a mesage sent with this routine.
 * @param handle The address of a globus_io handle opened by a connection being made to a server, or an Open_Client
 * 	call being made.
 * @param data_buffer A pointer to memory of length data_buffer__length, 
 * 	that should not be NULL and contains the binary data to send.
 * @param data_buffer_length The length of data to send, in bytes.
 * @return The routine returns GLOBUS_TRUE if the message was sent successfully, and GLOBUS_FALSE
 * 	if something failed. eSTAR_IO_Error_Number and eSTAR_IO_Error_String is filled in with the error
 * 	if something failed.
 * @see #eSTAR_IO_Write_Message
 * @see #eSTAR_IO_Read_Message
 * @see #ESTAR_IO_MESSAGE_SIZE_LENGTH
 */
int eSTAR_IO_Write_Binary_Message(globus_io_handle_t *handle,void *data_buffer,size_t data_buffer_length)
{
	globus_byte_t *message_block = NULL;
	globus_result_t result;
	globus_size_t bytes_written;
	globus_object_t* globus_error = NULL;
	char *error_string = NULL;
	globus_size_t message_length;

	if(handle == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 23;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Binary_Message:handle was NULL.");
		return GLOBUS_FALSE;
	}
	if(data_buffer == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 24;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Binary_Message:data buffer was NULL.");
		return GLOBUS_FALSE;
	}
/* allocate message block */
	message_block = globus_libc_malloc((data_buffer_length+ESTAR_IO_MESSAGE_SIZE_LENGTH)*sizeof(char));
	if(message_block == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 25;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Binary_Message:memory allocation error(%d).",
			(data_buffer_length+ESTAR_IO_MESSAGE_SIZE_LENGTH));
		return GLOBUS_FALSE;
	}
/* setup message block */
	message_length = htonl(data_buffer_length);
	memcpy(message_block,&message_length,ESTAR_IO_MESSAGE_SIZE_LENGTH);
	memcpy(message_block+ESTAR_IO_MESSAGE_SIZE_LENGTH,data_buffer,data_buffer_length);
/* send message block */
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Write_Binary_Message: about to send buffer of length '%d'.\n",
		(data_buffer_length+ESTAR_IO_MESSAGE_SIZE_LENGTH)*sizeof(char));
#endif
	result = globus_io_write(handle,message_block,data_buffer_length+ESTAR_IO_MESSAGE_SIZE_LENGTH,&bytes_written);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		globus_libc_free(message_block);
		eSTAR_IO_Error_Number = 29;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Write_Binary_Message:write error(%d,%d,%s).",
			data_buffer_length,bytes_written,error_string);
		return GLOBUS_FALSE;
	}
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Write_Binary_Message: sent buffer of length %d.\n",bytes_written);
#endif
/* free allocated memory */
	globus_libc_free(message_block);
	return GLOBUS_TRUE;
}

/**
 * Routine to read a text message from a globus_io stream represented by handle.
 * Note this routine will also read a fixed length binary message, as it relies on the buffer length integer
 * prepended to the message rather than a NULL terminator (which will be added to binary data). 
 * @param handle The address of a globus_io handle opened by a connection being made to a server, or an Open_Client
 * 	call being made.
 * @param message The address of a character pointer to store the read message into.
 * 	This should be freed with: <code>globus_libc_free(message);</code>
 * @see #ESTAR_IO_MESSAGE_SIZE_LENGTH
 * @see #eSTAR_IO_Write_Message
 * @see #eSTAR_IO_Write_Binary_Message
 */
int eSTAR_IO_Read_Message(globus_io_handle_t *handle,char **message)
{
	globus_result_t result;
	globus_size_t bytes_read;
	globus_object_t* globus_error = NULL;
	char *error_string = NULL;
	globus_byte_t message_length_buffer[ESTAR_IO_MESSAGE_SIZE_LENGTH];
	globus_size_t message_length;

	if(handle == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 5;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Read_Message:handle was NULL.");
		return GLOBUS_FALSE;
	}
	if(message == GLOBUS_NULL)
	{
		eSTAR_IO_Error_Number = 6;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Read_Message:message was NULL.");
		return GLOBUS_FALSE;
	}
/* initialse message */
	(*message) = NULL;
/* read byes containing length of rest of message */
	result = globus_io_read(handle,message_length_buffer,ESTAR_IO_MESSAGE_SIZE_LENGTH,
		ESTAR_IO_MESSAGE_SIZE_LENGTH,&bytes_read);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 7;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Read_Message:read error(%d,%s).",
			bytes_read,error_string);
		return GLOBUS_FALSE;
	}
/* convert to integer */
	memcpy(&message_length,message_length_buffer,ESTAR_IO_MESSAGE_SIZE_LENGTH);
	message_length = ntohl(message_length);
	if(message_length < 1)
	{
		eSTAR_IO_Error_Number = 8;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Read_Message:message length error(%d).",
			message_length);
		return GLOBUS_FALSE;
	}
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Read_Message: message length is '%d'\n",message_length);
#endif
/* allocate message buffer */
	(*message) = globus_libc_malloc((message_length+1)*sizeof(char));
	if((*message) == NULL)
	{
		eSTAR_IO_Error_Number = 9;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Read_Message:memory allocation error(%d).",
			message_length);
		return GLOBUS_FALSE;
	}
/* read actual message */
	result = globus_io_read(handle,(*message),message_length,message_length,&bytes_read);
	if(result != GLOBUS_SUCCESS)
	{
		globus_error = globus_error_get(result);
		globus_libc_free((*message));
		(*message) = NULL;
		error_string = globus_object_printable_to_string(globus_error);
		eSTAR_IO_Error_Number = 10;
		sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Read_Message:read error(%d,%d,%s).",
			message_length,bytes_read,error_string);
		return GLOBUS_FALSE;
	}
/* do something with message */
	(*message)[message_length] = '\0';
/* Note, this next debug line is dangerous with binary data */
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("eSTAR_IO_Read_Message: received '%s'\n",(*message));
#endif
	return GLOBUS_TRUE;
}

/**
 * Routine to print out the error to stderr.
 * @see #Get_Current_Time
 * @see #eSTAR_IO_Error_Number
 * @see #eSTAR_IO_Error_String
 */
void eSTAR_IO_Error(void)
{
	char time_string[32];

	Get_Current_Time(time_string,32);
	if(eSTAR_IO_Error_Number == 0)
		globus_libc_sprintf(eSTAR_IO_Error_String,"eSTAR_IO_Error:Internal Error:Error code was zero.\n");
	globus_libc_fprintf(stderr,"%s Error (%d) : %s\n",time_string,eSTAR_IO_Error_Number,eSTAR_IO_Error_String);
}
/* ----------------------------------------------
**	 internal function definitions 
** ---------------------------------------------- */
/**
 * Connection thread routine.
 * @param user_arg The thread specific data for this thread. In this case, this is the globus_io connection handle
 * 	for this thread.
 * @see #IO_Server_Connection_Callback
 * @see #Server_State
 */
static void *IO_Server_Connection_Thread(void *user_arg)
{
	globus_io_handle_t *connection_handle_ptr;
	globus_io_handle_t connection_handle;

	connection_handle_ptr = (globus_io_handle_t*)user_arg;
/* take a local copy of the connection handle, so we are not re-using the connection threads variable.
** Note there is potential for problems here, so this whilst spawning the thread? */
	connection_handle = (*connection_handle_ptr);
/* Call the connection callback.
** This should return GLOBUS_TRUE on exit, if the server is to keep running, 
** and GLOBUS_FALSE if the server is to terminate. */
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("IO_Server_Connection_Thread:connection callback about to be called\n");
#endif
	IO_Server_Connection_Callback(&connection_handle);
#ifdef ESTAR_IO_DEBUG
	globus_libc_printf("IO_Server_Connection_Thread:connection callback finished (Server_State=%d)\n",
				Server_State);
#endif
	globus_io_close(&connection_handle);
	return NULL;
}

/**
 * Internal routine to get the current time in a string. The string is returned in the format
 * '01/01/2000 13:59:59', or the string "Unknown time" if the routine failed.
 * @param time_string The string to fill with the current time.
 * @param string_length The length of the buffer passed in. It is recommended the length is at least 20 characters.
 */
static void Get_Current_Time(char *time_string,int string_length)
{
	time_t current_time;
	struct tm *utc_time = GLOBUS_NULL;

	if(time(&current_time) > -1)
	{
		utc_time = gmtime(&current_time);
		strftime(time_string,string_length,"%d/%m/%Y %H:%M:%S",utc_time);
	}
	else
		strncpy(time_string,"Unknown time",string_length);
}

/*
** $Log: estar_io.c,v $
** Revision 1.1  2002/03/04 23:29:22  aa
** Inital XS framework for eSTAR::IO library
**
** Revision 1.7  2002/01/30 18:37:53  cjm
** Fixed eSTAR_IO_Globus_IO_Attr error, so that servers and clients use different
** attrs to stop servers failing after the client destroys them.
** Note two clients cannot be open at once atm for this reason.
**
** Revision 1.6  2002/01/27 13:56:02  cjm
** Added eSTAR_IO_Write_Binary_Message.
**
** Revision 1.5  2002/01/22 17:11:31  cjm
** Changed Quit code.
**
** Revision 1.4  2002/01/17 11:30:56  cjm
** Message length now binary.
**
** Revision 1.3  2002/01/16 21:13:17  cjm
** POSIX changes.
**
** Revision 1.2  2002/01/14 11:21:09  cjm
** Fixed thread bug.
**
** Revision 1.1  2001/12/21 16:21:36  cjm
** Initial revision
**
*/
