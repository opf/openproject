# -*- ruby -*-
# frozen_string_literal: true

begin
	require 'pg_ext'
rescue LoadError
	# If it's a Windows binary gem, try the <major>.<minor> subdirectory
	if RUBY_PLATFORM =~/(mswin|mingw)/i
		major_minor = RUBY_VERSION[ /^(\d+\.\d+)/ ] or
			raise "Oops, can't extract the major/minor version from #{RUBY_VERSION.dump}"

		add_dll_path = proc do |path, &block|
			begin
				require 'ruby_installer/runtime'
				RubyInstaller::Runtime.add_dll_directory(path, &block)
			rescue LoadError
				old_path = ENV['PATH']
				ENV['PATH'] = "#{path};#{old_path}"
				block.call
				ENV['PATH'] = old_path
			end
		end

		# Temporary add this directory for DLL search, so that libpq.dll can be found.
		# mingw32-platform strings differ (RUBY_PLATFORM=i386-mingw32 vs. x86-mingw32 for rubygems)
		add_dll_path.call(File.join(__dir__, RUBY_PLATFORM.gsub(/^i386-/, "x86-"))) do
			require "#{major_minor}/pg_ext"
		end
	else
		raise
	end

end


# The top-level PG namespace.
module PG

	# Library version
	VERSION = '1.2.3'

	# VCS revision
	REVISION = %q$Revision: 6f611e78845a $

	class NotAllCopyDataRetrieved < PG::Error
	end

	### Get the PG library version. If +include_buildnum+ is +true+, include the build ID.
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end


	### Convenience alias for PG::Connection.new.
	def self::connect( *args )
		return PG::Connection.new( *args )
	end


	require 'pg/exceptions'
	require 'pg/constants'
	require 'pg/coder'
	require 'pg/binary_decoder'
	require 'pg/text_encoder'
	require 'pg/text_decoder'
	require 'pg/basic_type_mapping'
	require 'pg/type_map_by_column'
	require 'pg/connection'
	require 'pg/result'
	require 'pg/tuple'

end # module PG
