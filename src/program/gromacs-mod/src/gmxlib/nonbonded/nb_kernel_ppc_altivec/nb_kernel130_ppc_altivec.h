/* -*- mode: c; tab-width: 4; indent-tabs-mode: n; c-basic-offset: 4 -*- 
 *
 * $Id: nb_kernel130_ppc_altivec.h,v 1.1 2004/12/26 19:26:00 lindahl Exp $
 * 
 * This file is part of Gromacs        Copyright (c) 1991-1304
 * David van der Spoel, Erik Lindahl, University of Groningen.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * To help us fund GROMACS development, we humbly ask that you cite
 * the research papers on the package. Check out http://www.gromacs.org
 * 
 * And Hey:
 * Gnomes, ROck Monsters And Chili Sauce
 */
#ifndef _NB_KERNEL130_ALTIVEC_H_
#define _NB_KERNEL130_ALTIVEC_H_

/*! \file  nb_kernel130_ppc_altivec.h
 *  \brief Altivec-optimized versions of nonbonded kernel 130
 *
 *  \internal
 */


/*! \brief Nonbonded kernel 130 with forces, optimized for Altivec.
 *
 *  \internal
 *
 *  <b>Coulomb interaction:</b> Standard 1/r <br>
 *  <b>VdW interaction:</b> Tabulated <br>
 *  <b>Water optimization:</b> No <br>
 *  <b>Forces calculated:</b> Yes <br>
 *
 *  \note All level1 and level2 nonbonded kernels use the same
 *        call sequence. Parameters are documented in nb_kernel.h
 */
void
nb_kernel130_ppc_altivec  (int *   nri,        int     iinr[],   int     jindex[],
                       int     jjnr[],     int     shift[],  float   shiftvec[],
                       float   fshift[],   int     gid[],    float   pos[],
                       float   faction[],  float   charge[], float * facel,
                       float * krf,        float * crf,      float   Vc[],
                       int     type[],     int *   ntype,    float   vdwparam[],
                       float   Vvdw[],     float * tabscale, float   VFtab[],
                       float   invsqrta[], float   dvda[],   float * gbtabscale,
                       float   GBtab[],    int *   nthreads, int *   count,
                       void *  mtx,        int *   outeriter,int *   inneriter,
                       float * work);




/*! \brief Nonbonded kernel 130 without forces, optimized for Altivec.
 *
 *  \internal
 *
 *  <b>Coulomb interaction:</b> Standard 1/r <br>
 *  <b>VdW interaction:</b> Tabulated <br>
 *  <b>Water optimization:</b> No <br>
 *  <b>Forces calculated:</b> No <br>
 *
 *  \note All level1 and level2 nonbonded kernels use the same
 *        call sequence. Parameters are documented in nb_kernel.h
 */
void
nb_kernel130nf_ppc_altivec(int *   nri,        int     iinr[],   int     jindex[],
                       int     jjnr[],     int     shift[],  float   shiftvec[],
                       float   fshift[],   int     gid[],    float   pos[],
                       float   faction[],  float   charge[], float * facel,
                       float * krf,        float * crf,      float   Vc[],
                       int     type[],     int *   ntype,    float   vdwparam[],
                       float   Vvdw[],     float * tabscale, float   VFtab[],
                       float   invsqrta[], float   dvda[],   float * gbtabscale,
                       float   GBtab[],    int *   nthreads, int *   count,
                       void *  mtx,        int *   outeriter,int *   inneriter,
                       float * work);





#endif /* _NB_KERNEL130_ALTIVEC_H_ */
