module Sys
  class Filesystem
    # The version of the sys-filesystem library
    VERSION = '1.3.4'.freeze
  end
end

require 'rbconfig'

if File::ALT_SEPARATOR
  require_relative 'windows/sys/filesystem'
else
  require_relative 'unix/sys/filesystem'
end

# Methods universal to all platforms

module Sys
  class Filesystem
    class Stat
      # Returns true if the filesystem is case sensitive for the current path.
      # Typically this will be any path on MS Windows or Macs using HFS.
      #
      # For a root path (really any path without actual a-z characters) we
      # take a best guess based on the host operating system. However, as a
      # general rule, I do not recommend using this method for a root path.
      #
      def case_insensitive?
        if path !~ /\w+/
          if RbConfig::CONFIG['host_os'] =~ /darwin|mac|windows|mswin|mingw/i
            true # Assumes HFS
          else
            false
          end
        else
          File.identical?(path, path.swapcase)
        end
      end

      # Opposite of case_insensitive?
      #
      def case_sensitive?
        !case_insensitive?
      end
    end
  end
end

# Some convenient methods for converting bytes to kb, mb, and gb.
#
class Numeric
  # call-seq:
  #  <tt>num</tt>.to_kb
  #
  # Returns +num+ in terms of kilobytes.
  def to_kb
    self / 1024
  end

  # call-seq:
  #  <tt>num</tt>.to_mb
  #
  # Returns +num+ in terms of megabytes.
  def to_mb
    self / 1048576
  end

  # call-seq:
  #  <tt>num</tt>.to_gb
  #
  # Returns +num+ in terms of gigabytes.
  def to_gb
    self / 1073741824
  end

  # call-seq:
  #  <tt>num</tt>.to_gb
  #
  # Returns +num+ in terms of terabytes.
  def to_tb
    self / 1099511627776
  end
end
