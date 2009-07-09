/*  This file is part of "reprepro"
 *  Copyright (C) 2009 Bernhard R. Link
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02111-1301  USA
 */
#include <config.h>

#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#include "error.h"
#include "atoms.h"
#include "strlist.h"
#include "chunks.h"
#include "trackingt.h"
#include "tracking.h"
#include "globmatch.h"
#include "needbuild.h"

/* list all source packages in a distribution that needs buildd action

   For each source package check:
	- if tracking is enabled and there is a .log or .changes file
	  for the given arch -> SKIP
   	- if there is a binary package for the given architecture -> SKIP
	- if the package's Architecture field excludes this arch -> SKIP
	- if the package's Binary field only lists existing ones
          (i.e. architecture all) -> SKIP
*/

static retvalue tracked_source_needs_build(struct distribution *distribution, architecture_t architecture, const char *sourcename, const char *sourceversion, const char *dscfilename, const struct strlist *binary, const struct trackedpackage *tp) {
	bool found_binary[binary->count];
	const char *archstring = atoms_architectures[architecture];
	size_t archstringlen= strlen(archstring);
	int i;

	memset(found_binary, 0, sizeof(bool)*binary->count);
	for( i = 0 ; i < tp->filekeys.count ; i++ ) {
		enum filetype ft = tp->filetypes[i];
		const char *fk = tp->filekeys.values[i];

		if( ft == ft_XTRA_DATA )
			continue;
		if( ft == ft_ALL_BINARY ) {
			int j;

			/* determine which binary files are arch all
			   packages: */
			for( j = 0 ; j < binary->count ; j++ ) {
				const char *b = binary->values[j];
				size_t l = strlen(b);

				if( strncmp(fk, b, l) == 0 &&
						fk[l] == '_' )
					found_binary[j] = true;
			}
			continue;
		}
		if( ft == ft_ARCH_BINARY ) {
			const char *a = strrchr(fk, '_');

			if( a == NULL )
				continue;
			a++;
			if( strncmp(a, archstring, archstringlen) != 0 ||
					a[archstringlen] != '.' )
				continue;
			/* found an .deb with this architecture,
			   so nothing is to be done */
			return RET_NOTHING;
		}
		if( ft == ft_LOG || ft == ft_CHANGES ) {
			const char *a = strrchr(fk, '_');
			const char *e;

			if( a == NULL )
				continue;
			a++;
			while( (e = strchr(a, '+')) != NULL ) {
				if( (size_t)(e-a) != archstringlen ) {
					a = e+1;
					continue;
				}
				if( memcmp(a, archstring, archstringlen) != 0 ){
					a = e+1;
					continue;
				}
				/* found something for this architecture */
					return RET_NOTHING;
			}
			e = strchr(a, '.');
			if( e == NULL )
				continue;
			if( (size_t)(e-a) != archstringlen ) {
				a = e+1;
				continue;
			}
			if( memcmp(a, archstring, archstringlen) != 0 ){
				a = e+1;
				continue;
			}
			/* found something for this architecture */
			return RET_NOTHING;
		}
	}
	/* nothing for this architecture was found, check if is has any binary
	   packages that are lacking: */
	for( i = 0 ; i < binary->count ; i++ ) {
		if( !found_binary[i] ) {
			printf("%s %s %s\n",
					sourcename, sourceversion,
					dscfilename);
			return RET_OK;
		}
	}
	/* all things listed in Binary already exists, nothing to do: */
	return RET_NOTHING;
}

struct needbuild_data { architecture_t architecture;
	trackingdb tracks;
	/*@null@*/ const char *glob;
};

static retvalue check_source_needs_build(struct database *database, struct distribution *distribution, struct target *target, const char *sourcename, const char *control, void *data) {
	struct needbuild_data *d = data;
	char *sourceversion;
	struct strlist binary, architectures, filekeys;
	const char *dscfilename = NULL;
	int i;
	retvalue r;

	if( d->glob != NULL && !globmatch(sourcename, d->glob) )
		return RET_NOTHING;

	r = target->getversion(control, &sourceversion);
	if( !RET_IS_OK(r) )
		return r;
	r = chunk_getwordlist(control, "Architectures", &architectures);
	if( RET_IS_OK(r) ) {
		bool skip = true;

		for( i = 0 ; i < architectures.count ; i++ ) {
			const char *a = architectures.values[i];
			if( strcmp(a, "any") == 0 ) {
				skip = false;
				break;
			}
			if( strcmp(a, atoms_architectures[
						d->architecture]) == 0 ) {
				skip = false;
				break;
			}
		}
		strlist_done(&architectures);
		if( skip ) {
			free(sourceversion);
			return RET_NOTHING;
		}
	}
	r = chunk_getwordlist(control, "Binary", &binary);
	if( !RET_IS_OK(r) ) {
		free(sourceversion);
		return r;
	}
	r = target->getfilekeys(control, &filekeys);
	if( !RET_IS_OK(r) ) {
		strlist_done(&binary);
		free(sourceversion);
		return r;
	}
	for( i = 0 ; i < filekeys.count ; i++ ) {
		if( endswith(filekeys.values[i], ".dsc") ) {
			dscfilename = filekeys.values[i];
			break;
		}
	}
	if( dscfilename == NULL ) {
		fprintf(stderr,
"Warning: source package '%s' in '%s' without dsc file!\n",
				sourcename, target->identifier);
		free(sourceversion);
		strlist_done(&binary);
		strlist_done(&filekeys);
		return RET_NOTHING;
	}

	if( d->tracks != NULL ) {
		struct trackedpackage *tp;

		r = tracking_get(d->tracks, sourcename, sourceversion, &tp);
		if( RET_WAS_ERROR(r) ) {
			free(sourceversion);
			strlist_done(&binary);
			strlist_done(&filekeys);
			return r;
		}
		if( RET_IS_OK(r) ) {
			r = tracked_source_needs_build(distribution,
					d->architecture, sourcename,
					sourceversion, dscfilename,
					&binary, tp);
			trackedpackage_free(tp);
			free(sourceversion);
			strlist_done(&binary);
			strlist_done(&filekeys);
			return r;
		}
		fprintf(stderr, "Warning: %s's tracking data of %s (%s) is out of date. Run retrack to repair!\n", distribution->codename, sourcename, sourceversion);
	}
	// TODO: implement without tracking
	free(sourceversion);
	strlist_done(&binary);
	strlist_done(&filekeys);
	return RET_NOTHING;
}


retvalue find_needs_build(struct database *database, struct distribution *distribution, architecture_t architecture, component_t onlycomponent, const char *glob) {
	retvalue result, r;
	struct needbuild_data d;

	d.architecture = architecture;
	d.glob = glob;

	if( distribution->tracking == dt_NONE ) {
		fprintf(stderr,
"ERROR: '%s' has no source package Tracking enabled and\n"
"build-needing is currently only implemented for distributions where\n"
"this is enabled.\n"
"(i.e. you need to add e.g. Tracking: minimal in conf/distribution\n"
"and run retrack (and repeat running it after every update and pull.)\n",
			distribution->codename);
		return RET_ERROR;
	}

	if( distribution->tracking != dt_NONE ) {
		r = tracking_initialize(&d.tracks, database, distribution, true);
		if( RET_WAS_ERROR(r) )
			return r;
		if( r == RET_NOTHING )
			d.tracks = NULL;
	} else
			d.tracks = NULL;

	result = distribution_foreach_package(distribution, database,
			onlycomponent, architecture_source, pt_dsc,
			check_source_needs_build, NULL, &d);

	r = tracking_done(d.tracks);
	RET_ENDUPDATE(result, r);
	return result;
}
