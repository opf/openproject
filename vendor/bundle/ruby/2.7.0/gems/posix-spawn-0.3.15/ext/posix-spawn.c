/* we want GNU extensions like POSIX_SPAWN_USEVFORK */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE 1
#endif

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <ruby.h>

#ifdef RUBY_VM
#include <ruby/st.h>
#else
#include <st.h>
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(ary) RARRAY(ary)->len
#endif
#ifndef RARRAY_PTR
#define RARRAY_PTR(ary) RARRAY(ary)->ptr
#endif
#ifndef RHASH_SIZE
#define RHASH_SIZE(hash) RHASH(hash)->tbl->num_entries
#endif

#ifdef __APPLE__
#include <crt_externs.h>
#define environ (*_NSGetEnviron())
#else
extern char **environ;
#endif

static VALUE rb_mPOSIX;
static VALUE rb_mPOSIXSpawn;

/* Determine the fd number for a Ruby object VALUE.
 *
 * obj - This can be any valid Ruby object, but only the following return
 *       an actual fd number:
 *         - The symbols :in, :out, or :err for fds 0, 1, or 2.
 *         - An IO object. (IO#fileno is returned)
 *         - An Integer.
 *
 * Returns the fd number >= 0 if one could be established, or -1 if the object
 * does not map to an fd.
 */
static int
posixspawn_obj_to_fd(VALUE obj)
{
	int fd = -1;
	switch (TYPE(obj)) {
		case T_FIXNUM:
		case T_BIGNUM:
			/* Integer fd number
			 * rb_fix2int takes care of raising if the provided object is a
			 * Bignum and is out of range of an int
			 */
			fd = FIX2INT(obj);
			break;

		case T_SYMBOL:
			/* (:in|:out|:err) */
			if      (SYM2ID(obj) == rb_intern("in"))   fd = 0;
			else if (SYM2ID(obj) == rb_intern("out"))  fd = 1;
			else if (SYM2ID(obj) == rb_intern("err"))  fd = 2;
			break;

		case T_FILE:
			/* IO object */
			if (rb_respond_to(obj, rb_intern("posix_fileno"))) {
				fd = FIX2INT(rb_funcall(obj, rb_intern("posix_fileno"), 0));
			} else {
				fd = FIX2INT(rb_funcall(obj, rb_intern("fileno"), 0));
			}
			break;

		case T_OBJECT:
			/* some other object */
			if (rb_respond_to(obj, rb_intern("to_io"))) {
				obj = rb_funcall(obj, rb_intern("to_io"), 0);
				if (rb_respond_to(obj, rb_intern("posix_fileno"))) {
					fd = FIX2INT(rb_funcall(obj, rb_intern("posix_fileno"), 0));
				} else {
					fd = FIX2INT(rb_funcall(obj, rb_intern("fileno"), 0));
				}
			}
			break;
	}
	return fd;
}

/*
 * Hash iterator that sets up the posix_spawn_file_actions_t with addclose
 * operations. Only hash pairs whose value is :close are processed. Keys may
 * be the :in, :out, :err, an IO object, or an Integer fd number.
 *
 * Returns ST_DELETE when an addclose operation was added; ST_CONTINUE when
 * no operation was performed.
 */
static int
posixspawn_file_actions_addclose(VALUE key, VALUE val, posix_spawn_file_actions_t *fops)
{
	int fd;

	/* we only care about { (IO|FD|:in|:out|:err) => :close } */
	if (TYPE(val) != T_SYMBOL || SYM2ID(val) != rb_intern("close"))
		return ST_CONTINUE;

	fd  = posixspawn_obj_to_fd(key);
	if (fd >= 0) {
		/* raise an exception if 'fd' is invalid */
		if (fcntl(fd, F_GETFD) == -1) {
			char error_context[32];
			snprintf(error_context, sizeof(error_context), "when closing fd %d", fd);
			rb_sys_fail(error_context);
			return ST_DELETE;
		}
		posix_spawn_file_actions_addclose(fops, fd);
		return ST_DELETE;
	} else {
		return ST_CONTINUE;
	}
}

/*
 * Hash iterator that sets up the posix_spawn_file_actions_t with adddup2 +
 * close operations for all redirects. Only hash pairs whose key and value
 * represent fd numbers are processed.
 *
 * Returns ST_DELETE when an adddup2 operation was added; ST_CONTINUE when
 * no operation was performed.
 */
static int
posixspawn_file_actions_adddup2(VALUE key, VALUE val, posix_spawn_file_actions_t *fops)
{
	int fd, newfd;

	newfd = posixspawn_obj_to_fd(key);
	if (newfd < 0)
		return ST_CONTINUE;

	fd = posixspawn_obj_to_fd(val);
	if (fd < 0)
		return ST_CONTINUE;

	fcntl(fd, F_SETFD, fcntl(fd, F_GETFD) & ~FD_CLOEXEC);
	fcntl(newfd, F_SETFD, fcntl(newfd, F_GETFD) & ~FD_CLOEXEC);
	posix_spawn_file_actions_adddup2(fops, fd, newfd);
	return ST_DELETE;
}

/*
 * Hash iterator that sets up the posix_spawn_file_actions_t with adddup2 +
 * clone operations for all file redirects. Only hash pairs whose key is an
 * fd number and value is a valid three-tuple [file, flags, mode] are
 * processed.
 *
 * Returns ST_DELETE when an adddup2 operation was added; ST_CONTINUE when
 * no operation was performed.
 */
static int
posixspawn_file_actions_addopen(VALUE key, VALUE val, posix_spawn_file_actions_t *fops)
{
	int fd;
	char *path;
	int oflag;
	mode_t mode;

	fd = posixspawn_obj_to_fd(key);
	if (fd < 0)
		return ST_CONTINUE;

	if (TYPE(val) != T_ARRAY || RARRAY_LEN(val) != 3)
		return ST_CONTINUE;

	path = StringValuePtr(RARRAY_PTR(val)[0]);
	oflag = FIX2INT(RARRAY_PTR(val)[1]);
	mode = FIX2INT(RARRAY_PTR(val)[2]);

	posix_spawn_file_actions_addopen(fops, fd, path, oflag, mode);
	return ST_DELETE;
}

/*
 * Main entry point for iterating over the options hash to perform file actions.
 * This function dispatches to the addclose and adddup2 functions, stopping once
 * an operation was added.
 *
 * Returns ST_DELETE if one of the handlers performed an operation; ST_CONTINUE
 * if not.
 */
static int
posixspawn_file_actions_operations_iter(VALUE key, VALUE val, posix_spawn_file_actions_t *fops)
{
	int act;

	act = posixspawn_file_actions_addclose(key, val, fops);
	if (act != ST_CONTINUE) return act;

	act = posixspawn_file_actions_adddup2(key, val, fops);
	if (act != ST_CONTINUE) return act;

	act = posixspawn_file_actions_addopen(key, val, fops);
	if (act != ST_CONTINUE) return act;

	return ST_CONTINUE;
}

/*
 * Initialize the posix_spawn_file_actions_t structure and add operations from
 * the options hash. Keys in the options Hash that are processed by handlers are
 * removed.
 *
 * Returns nothing.
 */
static void
posixspawn_file_actions_init(posix_spawn_file_actions_t *fops, VALUE options)
{
	posix_spawn_file_actions_init(fops);
	rb_hash_foreach(options, posixspawn_file_actions_operations_iter, (VALUE)fops);
}

/*
 * Initialize pgroup related flags in the posix_spawnattr struct based on the
 * options Hash.
 *
 *   :pgroup => 0 | true - spawned process is in a new process group with the
 *                         same id as the new process's pid.
 *   :pgroup => pgid     - spawned process is in a new process group with id
 *                         pgid.
 *   :pgroup => nil      - spawned process has the same pgid as the parent
 *                         process (this is the default).
 *
 * The options Hash is modified in place with the :pgroup key being removed.
 */
static void
posixspawn_set_pgroup(VALUE options, posix_spawnattr_t *pattr, short *pflags)
{
	VALUE pgroup_val;
	pgroup_val = rb_hash_delete(options, ID2SYM(rb_intern("pgroup")));

	switch (TYPE(pgroup_val)) {
		case T_TRUE:
			(*pflags) |= POSIX_SPAWN_SETPGROUP;
			posix_spawnattr_setpgroup(pattr, 0);
			break;
		case T_FIXNUM:
			(*pflags) |= POSIX_SPAWN_SETPGROUP;
			posix_spawnattr_setpgroup(pattr, FIX2INT(pgroup_val));
			break;
		case T_NIL:
			break;
		default:
			rb_raise(rb_eTypeError, ":pgroup option is invalid");
			break;
	}
}

static int
each_env_check_i(VALUE key, VALUE val, VALUE arg)
{
	StringValuePtr(key);
	if (!NIL_P(val)) StringValuePtr(val);
	return ST_CONTINUE;
}

static int
each_env_i(VALUE key, VALUE val, VALUE arg)
{
	const char *name = StringValuePtr(key);
	const size_t name_len = strlen(name);

	char **envp = (char **)arg;
	size_t i, j;

	for (i = 0; envp[i];) {
		const char *ev = envp[i];

		if (strlen(ev) > name_len && !memcmp(ev, name, name_len) && ev[name_len] == '=') {
			/* This operates on a duplicated environment -- release the
			 * existing entry memory before shifting the subsequent entry
			 * pointers down. */
			free(envp[i]);

			for (j = i; envp[j]; ++j)
				envp[j] = envp[j + 1];
			continue;
		}
		i++;
	}

	/*
	 * Insert the new value if we have one. We can assume there is space
	 * at the end of the list, since ep was preallocated to be big enough
	 * for the new entries.
	 */
	if (RTEST(val)) {
		char **ep = (char **)arg;
		char *cval = StringValuePtr(val);

		size_t cval_len = strlen(cval);
		size_t ep_len = name_len + 1 + cval_len + 1; /* +2 for null terminator and '=' separator */

		/* find the last entry */
		while (*ep != NULL) ++ep;
		*ep = malloc(ep_len);

		strncpy(*ep, name, name_len);
		(*ep)[name_len] = '=';
		strncpy(*ep + name_len + 1, cval, cval_len);
		(*ep)[ep_len-1] = 0;
	}

	return ST_CONTINUE;
}

/*
 * POSIX::Spawn#_pspawn(env, argv, options)
 *
 * env     - Hash of the new environment.
 * argv    - The [[cmdname, argv0], argv1, ...] exec array.
 * options - The options hash with fd redirect and close operations.
 *
 * Returns the pid of the newly spawned process.
 */
static VALUE
rb_posixspawn_pspawn(VALUE self, VALUE env, VALUE argv, VALUE options)
{
	int i, ret = 0;
	char **envp = NULL;
	VALUE dirname;
	VALUE cmdname;
	VALUE unsetenv_others_p = Qfalse;
	char *file;
	char *cwd = NULL;
	pid_t pid;
	posix_spawn_file_actions_t fops;
	posix_spawnattr_t attr;
	sigset_t mask;
	short flags = 0;

	/* argv is a [[cmdname, argv0], argv1, argvN, ...] array. */
	if (TYPE(argv) != T_ARRAY ||
	    TYPE(RARRAY_PTR(argv)[0]) != T_ARRAY ||
	    RARRAY_LEN(RARRAY_PTR(argv)[0]) != 2)
		rb_raise(rb_eArgError, "Invalid command name");

	long argc = RARRAY_LEN(argv);
	char *cargv[argc + 1];

	cmdname = RARRAY_PTR(argv)[0];
	file = StringValuePtr(RARRAY_PTR(cmdname)[0]);

	cargv[0] = StringValuePtr(RARRAY_PTR(cmdname)[1]);
	for (i = 1; i < argc; i++)
		cargv[i] = StringValuePtr(RARRAY_PTR(argv)[i]);
	cargv[argc] = NULL;

	if (TYPE(options) == T_HASH) {
		unsetenv_others_p = rb_hash_delete(options, ID2SYM(rb_intern("unsetenv_others")));
	}

	if (RTEST(env)) {
		/*
		 * Make sure env is a hash, and all keys and values are strings.
		 * We do this before allocating space for the new environment to
		 * prevent a leak when raising an exception after the calloc() below.
		 */
		Check_Type(env, T_HASH);
		rb_hash_foreach(env, each_env_check_i, 0);

		if (RHASH_SIZE(env) > 0) {
			int size = 0;
			char **new_env;

			char **curr = environ;
			if (curr) {
				while (*curr != NULL) ++curr, ++size;
			}

			if (unsetenv_others_p == Qtrue) {
				/*
				 * ignore the parent's environment by pretending it had
				 * no entries. the loop below will do nothing.
				 */
				size = 0;
			}

			new_env = calloc(size+RHASH_SIZE(env)+1, sizeof(char*));
			for (i = 0; i < size; i++) {
				new_env[i] = strdup(environ[i]);
			}
			envp = new_env;

			rb_hash_foreach(env, each_env_i, (VALUE)envp);
		}
	}

	posixspawn_file_actions_init(&fops, options);
	posix_spawnattr_init(&attr);

	/* child does not block any signals */
	flags |= POSIX_SPAWN_SETSIGMASK;
	sigemptyset(&mask);
	posix_spawnattr_setsigmask(&attr, &mask);

	/* Child reverts SIGPIPE handler to the default. */
	flags |= POSIX_SPAWN_SETSIGDEF;
	sigaddset(&mask, SIGPIPE);
	posix_spawnattr_setsigdefault(&attr, &mask);

#if defined(POSIX_SPAWN_USEVFORK) || defined(__GLIBC__)
	/* Force USEVFORK on GNU libc. If this is undefined, it's probably
	 * because you forgot to define _GNU_SOURCE at the top of this file.
	 */
	flags |= POSIX_SPAWN_USEVFORK;
#endif

	/* setup pgroup options */
	posixspawn_set_pgroup(options, &attr, &flags);

	posix_spawnattr_setflags(&attr, flags);

	if (RTEST(dirname = rb_hash_delete(options, ID2SYM(rb_intern("chdir"))))) {
		char *new_cwd = StringValuePtr(dirname);
		cwd = getcwd(NULL, 0);
		if (chdir(new_cwd) == -1) {
			free(cwd);
			cwd = NULL;
			ret = errno;
		}
	}

	if (ret == 0) {
		if (RHASH_SIZE(options) == 0) {
			ret = posix_spawnp(&pid, file, &fops, &attr, cargv, envp ? envp : environ);
			if (cwd) {
				/* Ignore chdir failures here.  There's already a child running, so
				 * raising an exception here would do more harm than good. */
				if (chdir(cwd) == -1) {}
			}
		} else {
			ret = -1;
		}
	}

	if (cwd)
		free(cwd);

	posix_spawn_file_actions_destroy(&fops);
	posix_spawnattr_destroy(&attr);
	if (envp) {
		char **ep = envp;
		while (*ep != NULL) free(*ep), ++ep;
		free(envp);
	}

	if (RHASH_SIZE(options) > 0) {
		rb_raise(rb_eArgError, "Invalid option: %s", RSTRING_PTR(rb_inspect(rb_funcall(options, rb_intern("first"), 0))));
		return -1;
	}

	if (ret != 0) {
		char error_context[PATH_MAX+32];
		snprintf(error_context, sizeof(error_context), "when spawning '%s'", file);
		errno = ret;
		rb_sys_fail(error_context);
	}

	return INT2FIX(pid);
}

void
Init_posix_spawn_ext()
{
	rb_mPOSIX = rb_define_module("POSIX");
	rb_mPOSIXSpawn = rb_define_module_under(rb_mPOSIX, "Spawn");
	rb_define_method(rb_mPOSIXSpawn, "_pspawn", rb_posixspawn_pspawn, 3);
}

/* vim: set noexpandtab sts=0 ts=4 sw=4: */
