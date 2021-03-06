/*
 * $Id: gmx_fft.h,v 1.1.2.3 2008/02/29 07:02:41 spoel Exp $
 * 
 *                This source code is part of
 * 
 *                 G   R   O   M   A   C   S
 * 
 *          GROningen MAchine for Chemical Simulations
 * 
 *                        VERSION 3.3.3
 * Written by David van der Spoel, Erik Lindahl, Berk Hess, and others.
 * Copyright (c) 1991-2000, University of Groningen, The Netherlands.
 * Copyright (c) 2001-2008, The GROMACS development team,
 * check out http://www.gromacs.org for more information.

 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * If you want to redistribute modifications, please consider that
 * scientific software is very special. Version control is crucial -
 * bugs must be traceable. We will be happy to consider code for
 * inclusion in the official distribution, but derived work must not
 * be called official GROMACS. Details are found in the README & COPYING
 * files - if they are missing, get the official version at www.gromacs.org.
 * 
 * To help us fund GROMACS development, we humbly ask that you cite
 * the papers on the package - you can find them in the top README file.
 * 
 * For more info, check our website at http://www.gromacs.org
 * 
 * And Hey:
 * Groningen Machine for Chemical Simulation
 */
#ifndef _GMX_FFT_H_
#define _GMX_FFT_H_

/*! \file gmx_fft.h
 *  \brief Fast Fourier Transforms.
 *
 *  This file provides an abstract Gromacs interface to Fourier transforms, 
 *  including multi-dimensional and real-to-complex transforms.
 *
 *  Internally it is implemented as wrappers to external libraries such
 *  as FFTW or the Intel Math Kernel Library, but we also have a built-in
 *  version of FFTPACK in case the faster alternatives are unavailable.
 *
 *  We also provide our own multi-dimensional transform setups even when
 *  the underlying library does not support it directly.
 *
 */

#include <stdio.h>

#include "types/simple.h"
#include "gmxcomplex.h"


#ifdef __cplusplus
extern "C" {
#endif
#if 0
} /* fixes auto-indentation problems */
#endif



/*! \brief Datatype for FFT setup 
 *
 *  The gmx_fft_t type contains all the setup information, e.g. twiddle
 *  factors, necessary to perform an FFT. Internally it is mapped to 
 *  whatever FFT library we are using, or the built-in FFTPACK if no fast
 *  external library is available.
 *
 *  Since some of the libraries (e.g. MKL) store work array data in their
 *  handles this datatype should only be used for one thread at a time, i.e.
 *  they should allocate one instance each when executing in parallel.
 */
typedef struct gmx_fft *
gmx_fft_t;




/*! \brief Specifier for FFT direction. 
 *
 *  The definition of the 1D forward transform from input x[] to output y[] is
 *  \f[
 *  y_{k} = \sum_{j=0}^{N-1} x_{j} \exp{-i 2 \pi j k /N}
 *  \f]
 *
 *  while the corresponding backward transform is
 *
 *  \f[
 *  y_{k} = \sum_{j=0}^{N-1} x_{j} \exp{i 2 \pi j k /N}
 *  \f]
 *
 *  A forward-backward transform pair will this result in data scaled by N.
 *
 *  For complex-to-complex transforms you can only use one of 
 *  GMX_FFT_FORWARD or GMX_FFT_BACKWARD, and for real-complex transforms you
 *  can only use GMX_FFT_REAL_TO_COMPLEX or GMX_FFT_COMPLEX_TO_REAL.
 */
enum gmx_fft_direction
{
    GMX_FFT_FORWARD,         /*!< Forward complex-to-complex transform  */
    GMX_FFT_BACKWARD,        /*!< Backward complex-to-complex transform */
    GMX_FFT_REAL_TO_COMPLEX, /*!< Real-to-complex valued fft            */
    GMX_FFT_COMPLEX_TO_REAL  /*!< Complex-to-real valued fft            */
};


/*! \brief Setup a 1-dimensional complex-to-complex transform 
 *
 *  \param fft  Pointer to opaque Gromacs FFT datatype
 *  \param nx   Length of transform 
 *
 *  \return status - 0 or a standard error message.
 *   
 *  \note Since some of the libraries (e.g. MKL) store work array data in their 
 *        handles this datatype should only be used for one thread at a time, 
 *        i.e. you should create one copy per thread when executing in parallel.
 */
int
gmx_fft_init_1d        (gmx_fft_t *       fft,
                        int               nx);



/*! \brief Setup a 1-dimensional real-to-complex transform 
 *
 *  \param fft  Pointer to opaque Gromacs FFT datatype
 *  \param nx   Length of transform in real space
 *
 *  \return status - 0 or a standard error message.
 *   
 *  \note Since some of the libraries (e.g. MKL) store work array data in their 
 *        handles this datatype should only be used for one thread at a time, 
 *        i.e. you should create one copy per thread when executing in parallel.
 */
int
gmx_fft_init_1d_real        (gmx_fft_t *       fft,
                             int               nx);



/*! \brief Setup a 2-dimensional complex-to-complex transform 
 *
 *  \param fft  Pointer to opaque Gromacs FFT datatype
 *  \param nx   Length of transform in first dimension
 *  \param ny   Length of transform in second dimension
 *
 *  \return status - 0 or a standard error message.
 *   
 *  \note Since some of the libraries (e.g. MKL) store work array data in their 
 *        handles this datatype should only be used for one thread at a time, 
 *        i.e. you should create one copy per thread when executing in parallel.
 */
int
gmx_fft_init_2d        (gmx_fft_t *         fft,
                        int                 nx, 
                        int                 ny);


/*! \brief Setup a 2-dimensional real-to-complex transform 
 *
 *  \param fft  Pointer to opaque Gromacs FFT datatype
 *  \param nx   Length of transform in first dimension
 *  \param ny   Length of transform in second dimension
 *
 *  The normal space is assumed to be real, while the values in
 *  frequency space are complex.
 *
 *  \return status - 0 or a standard error message.
 *   
 *  \note Since some of the libraries (e.g. MKL) store work array data in their 
 *        handles this datatype should only be used for one thread at a time, 
 *        i.e. you should create one copy per thread when executing in parallel.
 */
int
gmx_fft_init_2d_real        (gmx_fft_t *         fft,
                             int                 nx, 
                             int                 ny);


/*! \brief Setup a 3-dimensional complex-to-complex transform 
 *
 *  \param fft  Pointer to opaque Gromacs FFT datatype
 *  \param nx   Length of transform in first dimension
 *  \param ny   Length of transform in second dimension
 *  \param nz   Length of transform in third dimension
 *
 *  \return status - 0 or a standard error message.
 *   
 *  \note Since some of the libraries (e.g. MKL) store work array data in their 
 *        handles this datatype should only be used for one thread at a time, 
 *        i.e. you should create one copy per thread when executing in parallel.
 */
int
gmx_fft_init_3d        (gmx_fft_t *         fft,
                        int                 nx, 
                        int                 ny,
                        int                 nz);


/*! \brief Setup a 3-dimensional real-to-complex transform 
 *
 *  \param fft  Pointer to opaque Gromacs FFT datatype
 *  \param nx   Length of transform in first dimension
 *  \param ny   Length of transform in second dimension
 *  \param nz   Length of transform in third dimension
 *
 *  The normal space is assumed to be real, while the values in
 *  frequency space are complex.
 *
 *  \return status - 0 or a standard error message.
 *   
 *  \note Since some of the libraries (e.g. MKL) store work array data in their 
 *        handles this datatype should only be used for one thread at a time, 
 *        i.e. you should create one copy per thread when executing in parallel.
 */
int
gmx_fft_init_3d_real   (gmx_fft_t *         fft,
                        int                 nx, 
                        int                 ny,
                        int                 nz);



/*! \brief Perform a 1-dimensional complex-to-complex transform
 *
 *  Performs an instance of a transform previously initiated.
 *
 *  \param setup     Setup returned from gmx_fft_init_1d()
 *  \param dir       Forward or Backward
 *  \param in_data   Input grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *  \param out_data  Output grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *                   You can provide the same pointer for in_data and out_data
 *                   to perform an in-place transform.
 *
 * \return 0 on success, or an error code.
 *
 * \note Data pointers are declared as void, to avoid casting pointers 
 *       depending on your grid type.
 */
int 
gmx_fft_1d               (gmx_fft_t                  setup,
                          enum gmx_fft_direction     dir,
                          void *                     in_data,
                          void *                     out_data);


/*! \brief Perform a 1-dimensional real-to-complex transform
 *
 *  Performs an instance of a transform previously initiated.
 *
 *  \param setup     Setup returned from gmx_fft_init_1d_real()
 *  \param dir       Real-to-complex or complex-to-real
 *  \param in_data   Input grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *  \param out_data  Output grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *                   You can provide the same pointer for in_data and out_data
 *                   to perform an in-place transform.
 *
 * If you are doing an in-place transform, the array must be padded up to
 * an even integer length so n/2 complex numbers can fit. Out-of-place arrays
 * should not be padded (although it doesn't matter in 1d).
 *
 * \return 0 on success, or an error code.
 *
 * \note Data pointers are declared as void, to avoid casting pointers 
 *       depending on transform direction.
 */
int 
gmx_fft_1d_real          (gmx_fft_t                  setup,
                          enum gmx_fft_direction     dir,
                          void *                     in_data,
                          void *                     out_data);


/*! \brief Perform a 2-dimensional complex-to-complex transform
 *
 *  Performs an instance of a transform previously initiated.
 *
 *  \param setup     Setup returned from gmx_fft_init_1d()
 *  \param dir       Forward or Backward
 *  \param in_data   Input grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *  \param out_data  Output grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *                   You can provide the same pointer for in_data and out_data
 *                   to perform an in-place transform.
 *
 * \return 0 on success, or an error code.
 *
 * \note Data pointers are declared as void, to avoid casting pointers 
 *       depending on your grid type.
 */
int 
gmx_fft_2d               (gmx_fft_t                  setup,
                          enum gmx_fft_direction     dir,
                          void *                     in_data,
                          void *                     out_data);


/*! \brief Perform a 2-dimensional real-to-complex transform
 *
 *  Performs an instance of a transform previously initiated.
 *
 *  \param setup     Setup returned from gmx_fft_init_1d_real()
 *  \param dir       Real-to-complex or complex-to-real
 *  \param in_data   Input grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *  \param out_data  Output grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *                   You can provide the same pointer for in_data and out_data
 *                   to perform an in-place transform.
 *
 * \return 0 on success, or an error code.
 *
 * \note If you are doing an in-place transform, the last dimension of the
 * array MUST be padded up to an even integer length so n/2 complex numbers can 
 * fit. Thus, if the real grid e.g. has dimension 5*3, you must allocate it as
 * a 5*4 array, where the last element in the second dimension is padding.
 * The complex data will be written to the same array, but since that dimension
 * is 5*2 it will now fill the entire array. Reverse complex-to-real in-place
 * transformation will produce the same sort of padded array.
 *
 * The padding does NOT apply to out-of-place transformation. In that case the
 * input array will simply be 5*3 of real, while the output is 5*2 of complex.
 *
 * \note Data pointers are declared as void, to avoid casting pointers 
 *       depending on transform direction.
 */
int
gmx_fft_2d_real          (gmx_fft_t                  setup,
                          enum gmx_fft_direction     dir,
                          void *                     in_data,
                          void *                     out_data);


/*! \brief Perform a 3-dimensional complex-to-complex transform
 *
 *  Performs an instance of a transform previously initiated.
 *
 *  \param setup     Setup returned from gmx_fft_init_1d()
 *  \param dir       Forward or Backward
 *  \param in_data   Input grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *  \param out_data  Output grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *                   You can provide the same pointer for in_data and out_data
 *                   to perform an in-place transform.
 *
 * \return 0 on success, or an error code.
 *
 * \note Data pointers are declared as void, to avoid casting pointers 
 *       depending on your grid type.
 */
int 
gmx_fft_3d               (gmx_fft_t                  setup,
                          enum gmx_fft_direction     dir,
                          void *                     in_data,
                          void *                     out_data);


/*! \brief Perform a 3-dimensional real-to-complex transform
 *
 *  Performs an instance of a transform previously initiated.
 *
 *  \param setup     Setup returned from gmx_fft_init_1d_real()
 *  \param dir       Real-to-complex or complex-to-real
 *  \param in_data   Input grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *  \param out_data  Output grid data. This should be allocated with gmx_new()
 *                   to make it 16-byte aligned for better performance.
 *                   You can provide the same pointer for in_data and out_data
 *                   to perform an in-place transform.
 *
 * \return 0 on success, or an error code.
 *
 * \note If you are doing an in-place transform, the last dimension of the
 * array MUST be padded up to an even integer length so n/2 complex numbers can 
 * fit. Thus, if the real grid e.g. has dimension 7*5*3, you must allocate it as
 * a 7*5*4 array, where the last element in the second dimension is padding.
 * The complex data will be written to the same array, but since that dimension
 * is 7*5*2 it will now fill the entire array. Reverse complex-to-real in-place
 * transformation will produce the same sort of padded array.
 *
 * The padding does NOT apply to out-of-place transformation. In that case the
 * input will simply be 7*5*3 of real, while the output is 7*5*2 of complex.
 *
 * \note Data pointers are declared as void, to avoid casting pointers 
 *       depending on transform direction.
 */
int 
gmx_fft_3d_real          (gmx_fft_t                  setup,
                          enum gmx_fft_direction     dir,
                          void *                     in_data,
                          void *                     out_data);


/*! \brief Release an FFT setup structure 
 *
 *  Destroy setup and release all allocated memory.
 *
 *  \param setup Setup returned from gmx_fft_init_1d(), or one
 *		 of the other initializers.
 *
 */
void
gmx_fft_destroy          (gmx_fft_t                 setup);


/*! \brief Transpose 2d complex matrix, in-place or out-of-place.
 * 
 * This routines works when the matrix is non-square, i.e. nx!=ny too, 
 * without allocating an entire matrix of work memory, which is important
 * for huge FFT grids.
 *
 * \param in_data    Input data, to be transposed 
 * \param out_data   Output, transposed data. If this is identical to 
 *                   in_data, an in-place transpose is performed.
 * \param nx         Number of rows before transpose
 * \param ny         Number of columns before transpose
 *
 * \return GMX_SUCCESS, or an error code from gmx_errno.h
 */
int
gmx_fft_transpose_2d   (t_complex *       in_data,
                        t_complex *       out_data,
                        int               nx,
                        int               ny);


/*! \brief Transpose 2d multi-element matrix 
 * 
 * This routine is very similar to gmx_fft_transpose_2d(), but it 
 * supports matrices with more than one data value for each position.
 * It is extremely useful when transposing the x/y dimensions of a 3d
 * matrix - in that case you just set nelem to nz, and the routine will do
 * and x/y transpose where it moves entire columns of z data 
 *
 * This routines works when the matrix is non-square, i.e. nx!=ny too, 
 * without allocating an entire matrix of work memory, which is important
 * for huge FFT grid.
 *
 * For performance reasons you need to provide a \a small workarray 
 * with length at least 2*nelem (note that the type is char, not t_complex).
 *
 * \param in_data    Input data, to be transposed 
 * \param out_data   Output, transposed data. If this is identical to 
 *                   in_data, an in-place transpose is performed.
 * \param nx         Number of rows before transpose
 * \param ny         Number of columns before transpose
 * \param nelem      Number of t_complex values in each position. If this
 *                   is 1 it is faster to use gmx_fft_transpose_2d() directly.
 * \param work       Work array of length 2*nelem, type t_complex.
 *
 * \return GMX_SUCCESS, or an error code from gmx_errno.h
 */
int
gmx_fft_transpose_2d_nelem(t_complex *        in_data,
                           t_complex *        out_data,
                           int                nx,
                           int                ny,
                           int                nelem,
                           t_complex *        work);




#ifdef __cplusplus
}
#endif

#endif /* _GMX_FFT_H_ */
