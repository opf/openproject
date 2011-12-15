#-- encoding: UTF-8
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
    MINOR = 5
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
      @revision ||= begin
        git = Redmine::Scm::Adapters::GitAdapter
        git_dir = Rails.root.join('.git')

        if File.directory? git_dir
          git.send(:shellout, "#{git.sq_bin} --git-dir='#{git_dir}' rev-parse --short=9 HEAD") { |io| io.read }.to_s.chomp
        end
      end
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
