#ifndef REPREPRO_GLOBALS_H
#define REPREPRO_GLOBALS_H

#ifdef AVOID_CHECKPROBLEMS
# define bool _Bool
# define true (1==1)
# define false (0==42)
/* avoid problems with __builtin_expect being long instead of boolean */
# define __builtin_expect(a,b) (a)
# define __builtin_constant_p(a) (__builtin_constant_p(a) != 0)
#else
# if HAVE_STDBOOL_H
#  include <stdbool.h>
# else
#  if ! HAVE__BOOL
typedef int _Bool;
#  endif
#  define true (1==1)
#  define false (0==42)
# endif
#endif

#define xisspace(c) (isspace(c)!=0)
#define xisblank(c) (isblank(c)!=0)
#define xisdigit(c) (isdigit(c)!=0)

#define READONLY true
#define READWRITE false

#define ISSET(a,b) ((a&b)!=0)
#define NOTSET(a,b) ((a&b)==0)

#ifdef STUPIDCC
#define IFSTUPIDCC(a) a
#else
#define IFSTUPIDCC(a)
#endif

#ifdef SPLINT
#define UNUSED(a) /*@unused@*/ a
#define NORETURN
#define likely(a) (a)
#define unlikely(a) (a)
#else
#define likely(a) (!(__builtin_expect(!(a), false)))
#define unlikely(a) __builtin_expect(a, false)
#define NORETURN __attribute((noreturn))
#ifndef NOUNUSEDATTRIBUTE
#define UNUSED(a) a __attribute((unused))
#else
#define UNUSED(a) a
#endif
#endif

#define ARRAYCOUNT(a) (sizeof(a)/sizeof(a[0]))

enum config_option_owner { 	CONFIG_OWNER_DEFAULT=0,
				CONFIG_OWNER_FILE,
				CONFIG_OWNER_ENVIRONMENT,
		           	CONFIG_OWNER_CMDLINE};
#ifndef _D_EXACT_NAMELEN
#define _D_EXACT_NAMELEN(r) strlen((r)->d_name)
#endif
/* for systems defining NULL to 0 instead of the nicer (void*)0 */
#define ENDOFARGUMENTS ((char *)0)
#endif
