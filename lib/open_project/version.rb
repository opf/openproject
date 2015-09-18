#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rexml/document'

module OpenProject
  module VERSION #:nodoc:
    MAJOR = 4
    MINOR = 2
    PATCH = 8
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
      revision = `git rev-parse HEAD`
      if revision.present?
        revision.strip[0..8]
      else
        nil
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
