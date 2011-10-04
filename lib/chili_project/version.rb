#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rexml/document'

module ChiliProject
  module VERSION #:nodoc:

    MAJOR = 2
    MINOR = 3
    PATCH = 0
    TINY  = PATCH # Redmine compat

    # Used by semver to define the special version (if any).
    # A special version "satify but have a lower precedence than the associated
    # normal version". So 2.0.0RC1 would be part of the 2.0.0 series but
    # be considered to be an older version.
    #
    #   1.4.0 < 2.0.0RC1 < 2.0.0RC2 < 2.0.0 < 2.1.0
    #
    # This method may be overridden by third party code to provide vendor or
    # distribution specific versions. They may or may not follow semver.org:
    #
    #   2.0.0debian-2
    def self.special
      ''
    end

    def self.revision
      revision = nil
      entries_path = "#{RAILS_ROOT}/.svn/entries"
      if File.readable?(entries_path)
        begin
          f = File.open(entries_path, 'r')
          entries = f.read
          f.close
     	  if entries.match(%r{^\d+})
     	    revision = $1.to_i if entries.match(%r{^\d+\s+dir\s+(\d+)\s})
     	  else
   	        xml = REXML::Document.new(entries)
   	        revision = xml.elements['wc-entries'].elements[1].attributes['revision'].to_i
   	      end
   	    rescue
   	      # Could not find the current revision
   	    end
 	  end
 	  revision
    end

    REVISION = self.revision
    ARRAY = [MAJOR, MINOR, PATCH, REVISION].compact
    STRING = ARRAY.join('.')

    def self.to_a; ARRAY end
    def self.to_s; STRING end
    def self.to_semver
      [MAJOR, MINOR, PATCH].join('.') + special
    end
  end
end
