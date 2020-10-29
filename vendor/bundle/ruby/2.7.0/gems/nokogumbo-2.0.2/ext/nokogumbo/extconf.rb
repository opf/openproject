require 'rubygems'
require 'fileutils'
require 'mkmf'
require 'nokogiri'

$CFLAGS += " -std=c99"
$LDFLAGS.gsub!('-Wl,--no-undefined', '')
$warnflags = CONFIG['warnflags'] = '-Wall'

NG_SPEC = Gem::Specification.find_by_name('nokogiri', "= #{Nokogiri::VERSION}")

def download_headers
  begin
    require 'yaml'

    dependencies = YAML.load_file(File.join(NG_SPEC.gem_dir, 'dependencies.yml'))
    version = dependencies['libxml2']['version']
    host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
    path = File.join('ports', host, 'libxml2', version, 'include/libxml2')
    return path if File.directory?(path)

    # Make sure we're using the same version Nokogiri uses
    dep_index = NG_SPEC.dependencies.index { |dep| dep.name == 'mini_portile2' and dep.type == :runtime }
    return nil if dep_index.nil?
    requirement = NG_SPEC.dependencies[dep_index].requirement.to_s

    gem 'mini_portile2', requirement
    require 'mini_portile2'
    p = MiniPortile::new('libxml2', version).tap do |r|
      r.host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
      r.files = [{
        url: "http://xmlsoft.org/sources/libxml2-#{r.version}.tar.gz",
        sha256: dependencies['libxml2']['sha256']
      }]
      r.configure_options += [
        "--without-python",
        "--without-readline",
        "--with-c14n",
        "--with-debug",
        "--with-threads"
      ]
    end
    p.download unless p.downloaded?
    p.extract
    p.configure unless p.configured?
    system('make', '-C', "tmp/#{p.host}/ports/libxml2/#{version}/libxml2-#{version}/include/libxml", 'install-xmlincHEADERS')
    path
  rescue
    puts 'failed to download/install headers'
    nil
  end
end

required = arg_config('--with-libxml2')
prohibited = arg_config('--without-libxml2')
if required and prohibited
  abort "cannot use both --with-libxml2 and --without-libxml2"
end

have_libxml2 = false
have_ng = false

if !prohibited
  if Nokogiri::VERSION_INFO.include?('libxml') and
     Nokogiri::VERSION_INFO['libxml']['source'] == 'packaged'
    # Nokogiri has libxml2 built in. Find the headers.
    libxml2_path = File.join(Nokogiri::VERSION_INFO['libxml']['libxml2_path'],
                             'include/libxml2')
    if find_header('libxml/tree.h', libxml2_path)
      have_libxml2 = true
    else
      # Unfortunately, some versions of Nokogiri delete these files.
      # https://github.com/sparklemotion/nokogiri/pull/1788
      # Try to download them
      libxml2_path = download_headers
      unless libxml2_path.nil?
        have_libxml2 = find_header('libxml/tree.h', libxml2_path)
      end
    end
  else
    # Nokogiri is compiled with system headers.
    # Hack to work around broken mkmf on macOS
    # (https://bugs.ruby-lang.org/issues/14992 fixed now)
    if RbConfig::MAKEFILE_CONFIG['LIBPATHENV'] == 'DYLD_LIBRARY_PATH'
      RbConfig::MAKEFILE_CONFIG['LIBPATHENV'] = 'DYLD_FALLBACK_LIBRARY_PATH'
    end

    pkg_config('libxml-2.0')
    have_libxml2 = have_library('xml2', 'xmlNewDoc')
  end
  if required and !have_libxml2
    abort "libxml2 required but could not be located"
  end

  if have_libxml2
    # Find nokogiri.h
    have_ng = find_header('nokogiri.h', File.join(NG_SPEC.gem_dir, 'ext/nokogiri'))
  end
end

if have_libxml2 and have_ng
  $CFLAGS += " -DNGLIB=1"
end

# Symlink gumbo-parser source files.
ext_dir = File.dirname(__FILE__)
gumbo_src = File.join(ext_dir, 'gumbo_src')

Dir.chdir(ext_dir) do
  $srcs = Dir['*.c', '../../gumbo-parser/src/*.c']
  $hdrs = Dir['*.h', '../../gumbo-parser/src/*.h']
end
$INCFLAGS << ' -I$(srcdir)/../../gumbo-parser/src'
$VPATH << '$(srcdir)/../../gumbo-parser/src'

create_makefile('nokogumbo/nokogumbo') do |conf|
  conf.map! do |chunk|
    chunk.gsub(/^HDRS = .*$/, "HDRS = #{$hdrs.map { |h| File.join('$(srcdir)', h)}.join(' ')}")
  end
end
# vim: set sw=2 sts=2 ts=8 et:
