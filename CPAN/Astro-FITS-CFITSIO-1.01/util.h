#ifndef CFITSIO_PERL_UTIL_H
#define CFITSIO_PERL_UTIL_H

#include "fitsio.h"

#define FIXME(s)

typedef char logical;
typedef unsigned char byte;
typedef float cmp;
typedef double dblcmp;

void * pack1D( SV * arg, int datatype );
void * packND( SV * arg, int datatype );
void pack_element( SV* work, SV** arg, int datatype );

void* get_mortalspace( long n, int datatype );
AV* coerce1D ( SV* arg, long n );
AV* coerceND ( SV* arg, int ndims, long *dims );
void unpack1D ( SV* arg, void * var, long n, int datatype );
void unpack2D ( SV* arg, void * var, long *dims, int datatype );
void unpack3D ( SV* arg, void * var, long *dims, int datatype );
void unpackND ( SV* arg, void * var, int ndims, long *dims, int datatype );
void unpack2scalar ( SV* arg, void * var, long n, int datatype );
void unpackScalar( SV* arg, void *var, int datatype );
void swap_dims(int ndims, long *dims);
int PerlyUnpacking(int value);
int sizeof_datatype(int datatype);
long column_width(fitsfile * fptr, int colnum);
void check_status(int status);
void order_reverse (int nelem, long *vals);

#endif /* CFITSIO_PERL_UTIL_H */
