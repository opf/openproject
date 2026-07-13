# frozen_string_literal: true

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

module OpenProject
  module SCM
    module LocalPathValidator
      module_function

      def points_to_openproject_directory?(value)
        path = local_path(value)
        return false if path.blank?

        forbidden_roots.any? { |root| path_within_root?(path, root) }
      end

      def local_path(value)
        return if value.blank?

        raw_path = begin
          parsed = URI.parse(value)
          case parsed.scheme&.downcase
          when "file"
            # Use the path component extracted by the URI library.
            # file:////path gives parsed.path = "//path"; we normalise below.
            parsed.path
          when nil
            # Bare absolute path or an authority-relative reference such as
            # ///path, which Ruby's URI library sometimes rejects as invalid.
            value
          end
          # Any other scheme (http, https, git, svn, ssh) => nil => not local.
        rescue URI::Error
          # Malformed URI – treat as a raw string rather than silently ignoring
          # it, so that inputs like ///path cannot bypass the check.
          value
        end

        return if raw_path.blank?
        return unless raw_path.start_with?("/")

        # Collapse any run of leading slashes down to exactly one.
        #
        # POSIX allows "//" at the start of a path to have
        # implementation-defined meaning, and three or more leading slashes
        # are equivalent to one.  In practice File.expand_path preserves "//",
        # so "//path" would not match against the "/path"-rooted forbidden
        # roots.  Normalising here closes the remaining bypass vectors:
        #
        #   ///app/repos/foo     (URI::Error rescue path)
        #   file:////app/repos/foo  (parsed.path == "//app/repos/foo")
        #   //app/repos/foo      (double-slash bare path)
        normalized = raw_path.sub(/\A\/{2,}/, "/")

        File.expand_path(normalized)
      rescue ArgumentError
        nil
      end

      def forbidden_roots
        roots = [
          OpenProject::Configuration.scm_local_checkout_path,
          Repository::Git.managed_root,
          Repository::Subversion.managed_root
        ]

        roots.compact_blank.map { |root| File.expand_path(root) }.uniq
      end

      def path_within_root?(path, root)
        path == root || path.start_with?("#{root}/")
      end
    end
  end
end
