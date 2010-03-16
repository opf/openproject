#!/usr/bin/env ruby
module CodeRay

# = FileType
#
# A simple filetype recognizer.
#
# Copyright (c) 2006 by murphy (Kornelius Kalnbach) <murphy rubychan de>
#
# License:: LGPL / ask the author
# Version:: 0.1 (2005-09-01)
#
# == Documentation
#
#  # determine the type of the given
#   lang = FileType[ARGV.first]
#  
#   # return :plaintext if the file type is unknown
#   lang = FileType.fetch ARGV.first, :plaintext
#  
#   # try the shebang line, too
#   lang = FileType.fetch ARGV.first, :plaintext, true
module FileType

  UnknownFileType = Class.new Exception

  class << self

    # Try to determine the file type of the file.
    #
    # +filename+ is a relative or absolute path to a file.
    #
    # The file itself is only accessed when +read_shebang+ is set to true.
    # That means you can get filetypes from files that don't exist.
    def [] filename, read_shebang = false
      name = File.basename filename
      ext = File.extname(name).sub(/^\./, '')  # from last dot, delete the leading dot
      ext2 = filename.to_s[/\.(.*)/, 1]  # from first dot

      type =
        TypeFromExt[ext] ||
        TypeFromExt[ext.downcase] ||
        (TypeFromExt[ext2] if ext2) ||
        (TypeFromExt[ext2.downcase] if ext2) ||
        TypeFromName[name] ||
        TypeFromName[name.downcase]
      type ||= shebang(filename) if read_shebang

      type
    end

    def shebang filename
      begin
        File.open filename, 'r' do |f|
          if first_line = f.gets
            if type = first_line[TypeFromShebang]
              type.to_sym
            end
          end
        end
      rescue IOError
        nil
      end
    end

    # This works like Hash#fetch.
    #
    # If the filetype cannot be found, the +default+ value
    # is returned.
    def fetch filename, default = nil, read_shebang = false
      if default and block_given?
        warn 'block supersedes default value argument'
      end

      unless type = self[filename, read_shebang]
        return yield if block_given?
        return default if default
        raise UnknownFileType, 'Could not determine type of %p.' % filename
      end
      type
    end

  end

  TypeFromExt = {
    'c' => :c,
    'css' => :css,
    'diff' => :diff,
    'dpr' => :delphi,
    'groovy' => :groovy,
    'gvy' => :groovy,
    'h' => :c,
    'htm' => :html,
    'html' => :html,
    'html.erb' => :rhtml,
    'java' => :java,
    'js' => :java_script,
    'json' => :json,
    'mab' => :ruby,
    'pas' => :delphi,
    'patch' => :diff,
    'php' => :php,
    'php3' => :php,
    'php4' => :php,
    'php5' => :php,
    'py' => :python,
    'py3' => :python,
    'pyw' => :python,
    'rake' => :ruby,
    'raydebug' => :debug,
    'rb' => :ruby,
    'rbw' => :ruby,
    'rhtml' => :rhtml,
    'rxml' => :ruby,
    'sch' => :scheme,
    'sql' => :sql,
    'ss' => :scheme,
    'xhtml' => :xhtml,
    'xml' => :xml,
    'yaml' => :yaml,
    'yml' => :yaml,
  }
  for cpp_alias in %w[cc cpp cp cxx c++ C hh hpp h++ cu]
    TypeFromExt[cpp_alias] = :cpp
  end

  TypeFromShebang = /\b(?:ruby|perl|python|sh)\b/

  TypeFromName = {
    'Rakefile' => :ruby,
    'Rantfile' => :ruby,
  }

end

end

if $0 == __FILE__
  $VERBOSE = true
  eval DATA.read, nil, $0, __LINE__ + 4
end

__END__
require 'test/unit'

class FileTypeTests < Test::Unit::TestCase
  
  include CodeRay
  
  def test_fetch
    assert_raise FileType::UnknownFileType do
      FileType.fetch ''
    end

    assert_throws :not_found do
      FileType.fetch '.' do
        throw :not_found
      end
    end

    assert_equal :default, FileType.fetch('c', :default)

    stderr, fake_stderr = $stderr, Object.new
    $err = ''
    def fake_stderr.write x
      $err << x
    end
    $stderr = fake_stderr
    FileType.fetch('c', :default) { }
    assert_equal "block supersedes default value argument\n", $err
    $stderr = stderr
  end

  def test_ruby
    assert_equal :ruby, FileType['test.rb']
    assert_equal :ruby, FileType['test.java.rb']
    assert_equal :java, FileType['test.rb.java']
    assert_equal :ruby, FileType['C:\\Program Files\\x\\y\\c\\test.rbw']
    assert_equal :ruby, FileType['/usr/bin/something/Rakefile']
    assert_equal :ruby, FileType['~/myapp/gem/Rantfile']
    assert_equal :ruby, FileType['./lib/tasks\repository.rake']
    assert_not_equal :ruby, FileType['test_rb']
    assert_not_equal :ruby, FileType['Makefile']
    assert_not_equal :ruby, FileType['set.rb/set']
    assert_not_equal :ruby, FileType['~/projects/blabla/rb']
  end

  def test_c
    assert_equal :c, FileType['test.c']
    assert_equal :c, FileType['C:\\Program Files\\x\\y\\c\\test.h']
    assert_not_equal :c, FileType['test_c']
    assert_not_equal :c, FileType['Makefile']
    assert_not_equal :c, FileType['set.h/set']
    assert_not_equal :c, FileType['~/projects/blabla/c']
  end

  def test_cpp
    assert_equal :cpp, FileType['test.c++']
    assert_equal :cpp, FileType['test.cxx']
    assert_equal :cpp, FileType['test.hh']
    assert_equal :cpp, FileType['test.hpp']
    assert_equal :cpp, FileType['test.cu']
    assert_equal :cpp, FileType['test.C']
    assert_not_equal :cpp, FileType['test.c']
    assert_not_equal :cpp, FileType['test.h']
  end

  def test_html
    assert_equal :html, FileType['test.htm']
    assert_equal :xhtml, FileType['test.xhtml']
    assert_equal :xhtml, FileType['test.html.xhtml']
    assert_equal :rhtml, FileType['_form.rhtml']
    assert_equal :rhtml, FileType['_form.html.erb']
  end

  def test_yaml
    assert_equal :yaml, FileType['test.yml']
    assert_equal :yaml, FileType['test.yaml']
    assert_equal :yaml, FileType['my.html.yaml']
    assert_not_equal :yaml, FileType['YAML']
  end

  def test_pathname
    require 'pathname'
    pn = Pathname.new 'test.rb'
    assert_equal :ruby, FileType[pn]
    dir = Pathname.new '/etc/var/blubb'
    assert_equal :ruby, FileType[dir + pn]
    assert_equal :cpp, FileType[dir + 'test.cpp']
  end

  def test_no_shebang
    dir = './test'
    if File.directory? dir
      Dir.chdir dir do
        assert_equal :c, FileType['test.c']
      end
    end
  end
  
  def test_shebang_empty_file
    require 'tmpdir'
    tmpfile = File.join(Dir.tmpdir, 'bla')
    File.open(tmpfile, 'w') { }  # touch
    assert_equal nil, FileType[tmpfile]
  end
  
  def test_shebang
    require 'tmpdir'
    tmpfile = File.join(Dir.tmpdir, 'bla')
    File.open(tmpfile, 'w') { |f| f.puts '#!/usr/bin/env ruby' }
    assert_equal :ruby, FileType[tmpfile, true]
  end

end
