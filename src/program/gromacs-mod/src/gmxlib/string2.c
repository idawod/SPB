/*
 * $Id: string2.c,v 1.29.4.5 2008/02/29 07:02:44 spoel Exp $
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
/* This file is completely threadsafe - keep it that way! */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <sys/types.h>
#ifdef HAVE_UNISTD
#include <pwd.h>
#endif
#include <time.h>

#include "typedefs.h"
#include "smalloc.h"
#include "gmx_fatal.h"
#include "macros.h"
#include "string2.h"

int continuing(char *s)
/* strip trailing spaces and if s ends with a CONTINUE remove that too.
 * returns TRUE if s ends with a CONTINUE, FALSE otherwise.
 */
{
  int sl;

  rtrim(s);
  sl = strlen(s);
  if ((sl > 0) && (s[sl-1] == CONTINUE)) {
    s[sl-1] = 0;
    return TRUE;
  }
  else
    return FALSE;
}

char *fgets2(char *line, int n, FILE *stream)
/* This routine reads a string from stream of max length n
 * and zero terminated, without newlines
 * line should be long enough (>= n)
 */
{
  char *c;
  if (fgets(line,n,stream)==NULL) return NULL;
  if ((c=strchr(line,'\n'))!=NULL) *c=0;
  return line;
}

void strip_comment (char *line)
{
  char *c;

  if (!line)
    return;

  /* search for a comment mark and replace it by a zero */
  if ((c = strchr(line,COMMENTSIGN)) != NULL) 
    (*c) = 0;
}

void upstring (char *str)
{
  int i;

  for (i=0; (i < (int)strlen(str)); i++) 
    str[i] = toupper(str[i]);
}

void ltrim (char *str)
{
  char *tr;
  int c;

  if (!str)
    return;

  tr = strdup (str);
  c  = 0;
  while ((tr[c] == ' ') || (tr[c] == '\t'))
    c++;

  strcpy (str,tr+c);
  free (tr);
}

void rtrim (char *str)
{
  int nul;

  if (!str)
    return;

  nul = strlen(str)-1;
  while ((nul > 0) && ((str[nul] == ' ') || (str[nul] == '\t')) ) {
    str[nul] = '\0';
    nul--;
  }
}

void trim (char *str)
{
  ltrim (str);
  rtrim (str);
}

void nice_header (FILE *out,char *fn)
{
  char   *unk = "onbekend";
  time_t clock;
  char   *user=NULL;
  int    gh;
  uid_t  uid;
  char   buf[256];
#ifdef HAVE_UNISTD
  struct passwd *pw;
#endif

  /* Print a nice header above the file */
  clock = time (0);
  fprintf (out,"%c\n",COMMENTSIGN);
  fprintf (out,"%c\tFile '%s' was generated\n",COMMENTSIGN,fn ? fn : unk);
  
#ifdef HAVE_UNISTD
  uid = getuid();
  pw  = getpwuid(uid);
  gh  = gethostname(buf,255);
  user= pw->pw_name;
#else
  uid = 0;
  gh  = -1;
#endif
  
  fprintf (out,"%c\tBy user: %s (%d)\n",COMMENTSIGN,
	   user ? user : unk,(int) uid);
  fprintf(out,"%c\tOn host: %s\n",COMMENTSIGN,(gh == 0) ? buf : unk);

  fprintf (out,"%c\tAt date: %s",COMMENTSIGN,ctime(&clock));
  fprintf (out,"%c\n",COMMENTSIGN);
}

int strcasecmp_min(const char *str1, const char *str2)
{
  char ch1,ch2;
  
  do
    {
      do
	ch1=toupper(*(str1++));
      while ((ch1=='-') || (ch1=='_'));
      do 
	ch2=toupper(*(str2++));
      while ((ch2=='-') || (ch2=='_'));
      if (ch1!=ch2) return (ch1-ch2);
    }
  while (ch1);
  return 0; 
}

int strncasecmp_min(const char *str1, const char *str2, int n)
{
  char ch1,ch2;
  char *stri1, *stri2;

  stri1=(char *)str1;
  stri2=(char *)str2;  
  do
    {
      do
	ch1=toupper(*(str1++));
      while ((ch1=='-') || (ch1=='_'));
      do 
	ch2=toupper(*(str2++));
      while ((ch2=='-') || (ch2=='_'));
      if (ch1!=ch2) return (ch1-ch2);
    }
  while (ch1 && (str1-stri1<n) && (str2-stri2<n));
  return 0; 
}

int gmx_strcasecmp(const char *str1, const char *str2)
{
  char ch1,ch2;
  
  do
    {
      ch1=toupper(*(str1++));
      ch2=toupper(*(str2++));
      if (ch1!=ch2) return (ch1-ch2);
    }
  while (ch1);
  return 0; 
}

int gmx_strncasecmp(const char *str1, const char *str2, int n)
{
  char ch1,ch2;
 
  if(n==0) 
    return 0;

  do
    {
      ch1=toupper(*(str1++));
      ch2=toupper(*(str2++));
      if (ch1!=ch2) return (ch1-ch2);
      n--;
    }
  while (ch1 && n);
  return 0; 
}

char *gmx_strdup(const char *src)
{
  char *dest;

  snew(dest,strlen(src)+1);
  strcpy(dest,src);
  
  return dest;
}

char *wrap_lines(const char *buf,int line_width, int indent,bool bIndentFirst)
{
  char *b2;
  int i,i0,i2,j,b2len,lspace=0,l2space=0;
  bool bFirst,bFitsOnLine;

  /* characters are copied from buf to b2 with possible spaces changed
   * into newlines and extra space added for indentation.
   * i indexes buf (source buffer) and i2 indexes b2 (destination buffer)
   * i0 points to the beginning of the current line (in buf, source)
   * lspace and l2space point to the last space on the current line
   * bFirst is set to prevent indentation of first line
   * bFitsOnLine says if the first space occurred before line_width, if 
   * that is not the case, we have a word longer than line_width which 
   * will also not fit on the next line, so we might as well keep it on 
   * the current line (where it also won't fit, but looks better)
   */
  
  b2=NULL;
  b2len=strlen(buf)+1+indent;
  snew(b2,b2len);
  i0=i2=0;
  if (bIndentFirst)
    for(i2=0; (i2<indent); i2++)
      b2[i2] = ' ';
  bFirst=TRUE;
  do {
    l2space = -1;
    /* find the last space before end of line */
    for(i=i0; ((i-i0 < line_width) || (l2space==-1)) && (buf[i]); i++) {
      b2[i2++] = buf[i];
      /* remember the position of a space */
      if (buf[i] == ' ') {
        lspace = i;
	l2space = i2-1;
      }
      /* if we have a newline before the line is full, reset counters */
      if (buf[i]=='\n' && buf[i+1]) { 
	i0=i+1;
	b2len+=indent;
	srenew(b2, b2len);
	/* add indentation after the newline */
	for(j=0; (j<indent); j++)
	  b2[i2++]=' ';
      }
    }
    /* If we are at the last newline, copy it */
    if (buf[i]=='\n' && !buf[i+1]) {
      b2[i2++] = buf[i++];
    }
    /* if we're not at the end of the string */
    if (buf[i]) {
      /* check if one word does not fit on the line */
      bFitsOnLine = (i-i0 <= line_width);
      /* reset line counters to just after the space */
      i0 = lspace+1;
      i2 = l2space+1;
      /* if the words fit on the line, and we're beyond the indentation part */
      if ( (bFitsOnLine) && (l2space >= indent) ) {
	/* start a new line */
	b2[l2space] = '\n';
	/* and add indentation */
	if (indent) {
	  if (bFirst) {
	    line_width-=indent;
	    bFirst=FALSE;
	  }
	  b2len+=indent;
	  srenew(b2, b2len);
	  for(j=0; (j<indent); j++)
	    b2[i2++]=' ';
	  /* no extra spaces after indent; */
	  while(buf[i0]==' ')
	    i0++;
	}
      }
    }
  } while (buf[i]);
  b2[i2] = '\0';
  
  return b2;
}



