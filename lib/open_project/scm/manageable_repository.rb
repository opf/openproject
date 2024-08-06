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
    module ManageableRepository
      def self.included(base)
        base.extend(ClassMethods)

        ##
        # Take note when projects are renamed and check for associated managed repositories
        OpenProject::Notifications.subscribe(OpenProject::Events::PROJECT_RENAMED) do |payload|
          repository = payload[:project]&.repository

          if repository&.managed?
            ::SCM::RelocateRepositoryJob.perform_later(repository)
          end
        end
      end

      module ClassMethods
        ##
        # We let SCM vendor implementation define their own
        # types (e.g., for differences in the management of
        # local vs. remote repositories).
        #
        # But if they are manageable by OpenProject, they must
        # expose this type through +available_types+.
        def managed_type
          :managed
        end

        ##
        # Reads from configuration whether new repositories of this kind
        # may be managed from OpenProject.
        def manageable?
          !(disabled_types.include?(managed_type) || managed_root.nil?)
        end

        ##
        # Returns the managed root for this repository vendor
        def managed_root
          scm_config[:manages]
        end

        ##
        # Returns the managed remote for this repository vendor,
        # if any. Use +manages_remote?+ to determine whether the configuration
        # specifies local or remote managed repositories.
        def managed_remote
          URI.parse(scm_config[:manages])
        rescue URI::Error
          nil
        end

        ##
        # Returns whether the managed root is a remote URL to post to
        def manages_remote?
          managed_remote.present? && managed_remote.absolute?
        end
      end

      def manageable?
        self.class.manageable?
      end

      ##
      # Determines whether this repository IS currently managed
      # by openproject
      def managed?
        scm_type.to_sym == self.class.managed_type
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
      # Used only in the creation of a repository, at a later point
      # in time, it is referred to in the root_url
      def managed_repository_path
        File.join(self.class.managed_root, repository_identifier)
      end

      ##
      # Returns the access url to the repository
      # May be overridden by descendants
      # Used only in the creation of a repository, at a later point
      # in time, it is referred to in the url
      def managed_repository_url
        "file://#{managed_repository_path}"
      end

      ##
      # Repository relative path from scm managed root.
      # Will be overridden by including models to, e.g.,
      # append '.git' to that path.
      def repository_identifier
        project.identifier
      end
    end
  end
end
