#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'rexml/document'
require 'open3'

module OpenProject
  module VERSION #:nodoc:
    MAJOR = 10
    MINOR = 6
    PATCH = 2
    TINY  = PATCH # Redmine compat

    class << self
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
      def special
        ''
      end

      def revision
        cached_or_block(:@revision) do
          revision, = Open3.capture3('git', 'rev-parse', 'HEAD')
          if revision.present?
            revision.strip[0..8]
          end
        end
      end

      def product_version
        cached_or_block(:@product_version) do
          path = Rails.root.join('config', 'PRODUCT_VERSION')
          if File.exists? path
            File.read(path)
          end
        end
      end

      ##
      # Get information on when this version was created / updated from either
      # 1. A RELEASE_DATE file
      # 2. From the git revision
      def updated_on
        release_date_from_file || release_date_from_git
      end

      def to_a; ARRAY end

      def to_s; STRING end

      def to_semver
        [MAJOR, MINOR, PATCH].join('.') + special
      end

      private

      def release_date_from_file
        cached_or_block(:@release_date_from_file) do
          path = Rails.root.join('config', 'RELEASE_DATE')
          if File.exists? path
            s = File.read(path)
            Date.parse(s)
          end
        end
      end

      def release_date_from_git
        cached_or_block(:@release_date_from_git) do
          date, = Open3.capture3('git', 'log', '-1', '--format=%cd', '--date=short')
          Date.parse(date) if date
        end
      end

      def cached_or_block(variable)
        return instance_variable_get(variable) if instance_variable_defined?(variable)

        value = begin
                  yield
                rescue StandardError
                  nil
                end

        instance_variable_set(variable, value)
      end
    end

    REVISION = revision
    ARRAY = [MAJOR, MINOR, PATCH, REVISION].compact
    STRING = ARRAY.join('.')
  end
end
