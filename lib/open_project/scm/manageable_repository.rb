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

module OpenProject
  module Scm
    module ManageableRepository
      ##
      # We let SCM vendor implementation define their own
      # types (e.g., for differences in the management of
      # local vs. remote repositories).
      #
      # But if they are manageable by OpenProject, they must
      # expose this type through +available_types+.
      MANAGED_TYPE = :managed
      ##
      # Reads from configuration whether new repositories of this kind
      # may be managed from OpenProject.
      def manageable?
        !managed_root.nil?
      end

      ##
      # Returns the managed root for this repository vendor
      def managed_root
        scm.config[:manages]
      end

      ##
      # Determines whether this repository IS currently managed
      # by openproject
      def managed?
        scm_type.to_sym == MANAGED_TYPE
      end

      ##
      # Allows descendants to perform actions
      # with the given repository after the managed
      # repository has been written to file system.
      def managed_repo_created(_args)
        nil
      end

      ##
      # Returns the absolute path to the repository
      # under the +managed_root+ path defined in the configuration
      # of this adapter.
      def managed_repository_path
        File.join(managed_root, repository_path)
      end

      ##
      # Returns the access url to the repository
      # May be overridden by descendants
      def managed_repository_url
        "file://#{managed_repository_path}"
      end

      protected

      ##
      # Repository relative path from scm managed root.
      # Will be overridden by including models to, e.g.,
      # append '.git' to that path.
      def repository_identifier
        project.identifier
      end

      private

      ##
      # Generate a uniquely identified path from the project
      # hierarchy.
      def repository_path
        parent_path = parent_projects_path
        if parent_path.empty?
          repository_identifier
        else
          File.join(parent_path, repository_identifier)
        end
      end

      ##
      # Determine the parent path of the given project
      def parent_projects_path
        parent_parts = []
        p = project
        while p.parent
          parent_id = p.parent.identifier.to_s
          parent_parts.unshift(parent_id)
          p = p.parent
        end

        File.join(*parent_parts)
      end
    end
  end
end
