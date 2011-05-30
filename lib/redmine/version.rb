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

module Redmine
  module VERSION #:nodoc:
    MAJOR = 1
    MINOR = 4
    PATCH = 0
    TINY  = PATCH # Redmine compat

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
