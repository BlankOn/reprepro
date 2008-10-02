#ifndef REPREPRO_DISTRIBUTION_H
#define REPREPRO_DISTRIBUTION_H

struct distribution;

#ifndef REPREPRO_ERROR_H
#include "error.h"
#warning "What's hapening here?"
#endif
#ifndef REPREPRO_DATABASE_H
#include "database.h"
#endif
#ifndef REPREPRO_STRLIST_H
#include "strlist.h"
#endif
#ifndef REPREPRO_TARGET_H
#include "target.h"
#endif
#ifndef REPREPRO_EXPORTS_H
#include "exports.h"
#endif
#ifndef REPREPRO_CONTENTS_H
#include "contents.h"
#endif
struct overrideinfo;
struct uploaders;

struct distribution {
	struct distribution *next;
	/* the primary name to access this distribution: */
	char *codename;
	/* for more helpfull error messages: */
	unsigned int firstline, lastline;
	/* additional information for the Release-file to be
	 * generated, may be NULL. only suite is sometimes used
	 * (and only for sanity checks) */
	/*@null@*/char *suite,*version;
	/*@null@*/char *origin,*label,*description,*notautomatic;
	/* What architectures and components are there */
	struct strlist architectures,components;
	/* which update rules to use */
	struct strlist updates;
	/* which rules to use to pull packages from other distributions */
	struct strlist pulls;
	/* the key to sign with, may be NULL: */
	/*@null@*/char *signwith;
	/* the override file to use by default */
	/*@null@*/char *deb_override,*udeb_override,*dsc_override;
	/* fake component prefix (and codename antisuffix) for Release files: */
	/*@null@*/char *fakecomponentprefix;
	/* only loaded when you've done it yourself: */
	struct {
		/*@null@*/struct overrideinfo *dsc,*deb,*udeb;
	} overrides;
	/* the list of components containing a debian-installer dir, normally only "main" */
	struct strlist udebcomponents;
	/* what kind of index files to generate */
	struct exportmode dsc,deb,udeb;
	/* is tracking enabled for this distribution? (NONE must be 0 so it is the default) */
	enum trackingtype { dt_NONE=0, dt_KEEP, dt_ALL, dt_MINIMAL } tracking;
	struct trackingoptions { bool includechanges:1;
		bool includebyhand:1;
		bool includelogs:1;
		bool needsources:1;
		bool keepsources:1;
		bool embargoalls:1;
		} trackingoptions;
	/* what content files to generate */
	struct contentsoptions contents;
	struct strlist contents_architectures,
		       contents_components,
		       contents_ucomponents;
	bool contents_architectures_set,
		       contents_components_set,
		       contents_ucomponents_set;
	/* A list of all targets contained in the distribution*/
	struct target *targets;
	/* a filename to look for who is allowed to upload packages */
	/*@null@*/char *uploaders;
	/* only loaded after _loaduploaders */
	/*@null@*/struct uploaders *uploaderslist;
	/* how and where to log */
	/*@null@*/struct logger *logger;
	/* a list of names beside Codename and Suite to accept .changes
	 * files via include */
	struct strlist alsoaccept;
	/* RET_NOTHING: do not export with EXPORT_CHANGED, EXPORT_NEVER
	 * RET_OK: export unless EXPORT_NEVER
	 * RET_ERROR_*: only export with EXPORT_FORCE */
	retvalue status;
	/* false: not looked at, do not export at all */
	bool lookedat;
	/* false: not requested, do not handle at all */
	bool selected;
};

retvalue distribution_get(struct distribution *all, const char *name, bool lookedat, /*@out@*/struct distribution **);

/* set lookedat, start logger, ... */
retvalue distribution_prepareforwriting(struct distribution *distribution);

typedef retvalue distribution_each_action(void *data, struct target *t, struct distribution *d);

typedef retvalue each_target_action(struct database *, struct distribution *, struct target *, void *);
typedef retvalue each_package_action(struct database *, struct distribution *, struct target *, const char *, const char *, void *);

/* call <action> for each package of <distribution> */
retvalue distribution_foreach_package(struct distribution *, struct database *, const char *component, const char *architecture, const char *packagetype, each_package_action, each_target_action, void *);
retvalue distribution_foreach_package_c(struct distribution *, struct database *, const struct strlist *components, const char *architecture, const char *packagetype, each_package_action, void *);

/* delete every package decider returns RET_OK for */
retvalue distribution_remove_packages(struct distribution *, struct database *, const char *component, const char *architecture, const char *packagetype, each_package_action decider, struct strlist *dereferenced, struct trackingdata *, void *);

/*@dependent@*/struct target *distribution_getpart(const struct distribution *distribution,const char *component,const char *architecture,const char *packagetype);

/* like distribtion_getpart, but returns NULL if there is no such target */
/*@null@*//*@dependent@*/struct target *distribution_gettarget(const struct distribution *distribution,const char *component,const char *architecture,const char *packagetype);
// /*@null@*//*@dependent@*/struct target *distribution_gettarget(const struct distribution *distribution,const char *component,const char *architecture,const char *packagetype);

retvalue distribution_fullexport(struct distribution *distribution, struct database *);

enum exportwhen {EXPORT_NEVER, EXPORT_CHANGED, EXPORT_NORMAL, EXPORT_FORCE };
retvalue distribution_export(enum exportwhen, struct distribution *, struct database *);

retvalue distribution_snapshot(struct distribution *distribution, struct database *, const char *name);

/* read the configuration from all distributions */
retvalue distribution_readall(/*@out@*/struct distribution **distributions);

/* mark all dists from <conf> fitting in the filter given in <argc,argv> */
retvalue distribution_match(struct distribution *alldistributions, int argc, const char *argv[], bool lookedat);

/* get a pointer to the apropiate part of the linked list */
struct distribution *distribution_find(struct distribution *distributions, const char *name);

retvalue distribution_freelist(/*@only@*/struct distribution *distributions);
retvalue distribution_exportandfreelist(enum exportwhen when, /*@only@*/struct distribution *distributions, struct database *);
retvalue distribution_exportlist(enum exportwhen when, /*@only@*/struct distribution *distributions, struct database *);

retvalue distribution_loadalloverrides(struct distribution *);
void distribution_unloadoverrides(struct distribution *distribution);

retvalue distribution_loaduploaders(struct distribution *);
void distribution_unloaduploaders(struct distribution *distribution);
#endif
