require 'pp'
require 'mkmf'


if ENV['MAINTAINER_MODE']
	$stderr.puts "Maintainer mode enabled."
	$CFLAGS <<
		' -Wall' <<
		' -ggdb' <<
		' -DDEBUG' <<
		' -pedantic'
end

if pgdir = with_config( 'pg' )
	ENV['PATH'] = "#{pgdir}/bin" + File::PATH_SEPARATOR + ENV['PATH']
end

if enable_config("windows-cross")
	# Avoid dependency to external libgcc.dll on x86-mingw32
	$LDFLAGS << " -static-libgcc"
	# Don't use pg_config for cross build, but --with-pg-* path options
	dir_config 'pg'

else
	# Native build

	pgconfig = with_config('pg-config') ||
		with_config('pg_config') ||
		find_executable('pg_config')

	if pgconfig && pgconfig != 'ignore'
		$stderr.puts "Using config values from %s" % [ pgconfig ]
		incdir = `"#{pgconfig}" --includedir`.chomp
		libdir = `"#{pgconfig}" --libdir`.chomp
		dir_config 'pg', incdir, libdir

		# Try to use runtime path linker option, even if RbConfig doesn't know about it.
		# The rpath option is usually set implicit by dir_config(), but so far not
		# on MacOS-X.
		if RbConfig::CONFIG["RPATHFLAG"].to_s.empty? && try_link('int main() {return 0;}', " -Wl,-rpath,#{libdir}")
			$LDFLAGS << " -Wl,-rpath,#{libdir}"
		end
	else
		$stderr.puts "No pg_config... trying anyway. If building fails, please try again with",
			" --with-pg-config=/path/to/pg_config"
		dir_config 'pg'
	end
end

if RUBY_VERSION >= '2.3.0' && /solaris/ =~ RUBY_PLATFORM
	append_cppflags( '-D__EXTENSIONS__' )
end

find_header( 'libpq-fe.h' ) or abort "Can't find the 'libpq-fe.h header"
find_header( 'libpq/libpq-fs.h' ) or abort "Can't find the 'libpq/libpq-fs.h header"
find_header( 'pg_config_manual.h' ) or abort "Can't find the 'pg_config_manual.h' header"

abort "Can't find the PostgreSQL client library (libpq)" unless
	have_library( 'pq', 'PQconnectdb', ['libpq-fe.h'] ) ||
	have_library( 'libpq', 'PQconnectdb', ['libpq-fe.h'] ) ||
	have_library( 'ms/libpq', 'PQconnectdb', ['libpq-fe.h'] )

if /mingw/ =~ RUBY_PLATFORM && RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
	# Work around: https://sourceware.org/bugzilla/show_bug.cgi?id=22504
	checking_for "workaround gcc version with link issue" do
		`#{RbConfig::MAKEFILE_CONFIG['CC']} --version`.chomp =~ /\s(\d+)\.\d+\.\d+(\s|$)/ &&
			$1.to_i >= 6 &&
			have_library(':libpq.lib') # Prefer linking to libpq.lib over libpq.dll if available
	end
end

# optional headers/functions
have_func 'PQsetSingleRowMode' or
	abort "Your PostgreSQL is too old. Either install an older version " +
	      "of this gem or upgrade your database to at least PostgreSQL-9.2."
have_func 'PQconninfo' # since PostgreSQL-9.3
have_func 'PQsslAttribute' # since PostgreSQL-9.5
have_func 'PQresultVerboseErrorMessage' # since PostgreSQL-9.6
have_func 'PQencryptPasswordConn' # since PostgreSQL-10
have_func 'PQresultMemorySize' # since PostgreSQL-12
have_func 'timegm'
have_func 'rb_gc_adjust_memory_usage' # since ruby-2.4

# unistd.h confilicts with ruby/win32.h when cross compiling for win32 and ruby 1.9.1
have_header 'unistd.h'
have_header 'inttypes.h'

checking_for "C99 variable length arrays" do
	$defs.push( "-DHAVE_VARIABLE_LENGTH_ARRAYS" ) if try_compile('void test_vla(int l){ int vla[l]; }')
end

create_header()
create_makefile( "pg_ext" )

