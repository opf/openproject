#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "rexml/document"
require "open3"

module OpenProject
  module VERSION # :nodoc:
    MAJOR = 17
    MINOR = 2
    PATCH = 5

    class << self
      def revision
        revision_from_core_sha || revision_from_git
      end

      def core_sha
        cached_or_block(:@core_sha) do
          read_optional "CORE_VERSION"
        end
      end

      def core_url
        cached_or_block(:@core_url) do
          read_optional "CORE_URL"
        end
      end

      def product_sha
        cached_or_block(:@product_sha) do
          read_optional "PRODUCT_VERSION"
        end
      end

      def product_url
        cached_or_block(:@product_url) do
          read_optional "PRODUCT_URL"
        end
      end

      def builder_sha
        cached_or_block(:@builder_sha) do
          read_optional "BUILDER_VERSION"
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

      def to_semver(separator: ".")
        [MAJOR, MINOR, PATCH].join(separator)
      end

      private

      def release_date_from_file
        cached_or_block(:@release_date_from_file) do
          path = Rails.root.join("RELEASE_DATE")
          if File.exist? path
            s = File.read(path)
            Time.zone.parse(s)
          end
        end
      end

      def release_date_from_git
        cached_or_block(:@release_date_from_git) do
          date, = Open3.capture3("git", "log", "-1", "--format=%cd", "--date=iso8601")
          Time.zone.parse(date) if date
        end
      end

      def revision_from_core_sha
        return unless core_sha.is_a?(String)

        core_sha.split.first
      end

      def revision_from_git
        cached_or_block(:@revision) do
          revision, = Open3.capture3("git", "rev-parse", "HEAD")
          if revision.present?
            revision.strip[0..8]
          end
        end
      end

      def read_optional(file)
        path = Rails.root.join(file)
        if File.exist? path
          String(File.read(path)).strip
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
    STRING = ARRAY.join(".")
  end
end
