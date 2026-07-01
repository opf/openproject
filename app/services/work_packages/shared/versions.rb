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

module WorkPackages
  module Shared
    module Versions
      private

      # Persists the version associations after a work package is saved.
      #
      # Two paths feed the "target" associations:
      #   * an explicit override (the *_replacements accessor was set) takes
      #     precedence and replaces the whole set.
      #   * otherwise, a plain change to version_id (the legacy single-version
      #     path) is mirrored into the associations so both stay consistent.
      #
      # Writing to version_id will be removed after all subsystems start using
      # target_versions instead
      def save_versions(work_package)
        if work_package.override_target_versions?
          replace_versions(work_package, "target", work_package.target_version_ids_replacements)
          update_legacy_version_field(work_package)
        elsif work_package.saved_change_to_version_id?
          new_ids = work_package.version_id ? [work_package.version_id] : []
          replace_versions(work_package, "target", new_ids)
        end

        if work_package.override_observed_in_versions?
          replace_versions(work_package, "observed_in", work_package.observed_in_version_ids_replacements)
        end
      end

      # Keeps the deprecated single version_id column in sync with the first
      # target version, so code still reading version_id sees a sensible value.
      # Can be dropped once the version_id column is removed.
      def update_legacy_version_field(work_package)
        work_package.version_id = work_package.target_version_ids_replacements&.first || nil
      end

      # Sets the work package's associations of the given kind to exactly the
      # given version_ids.
      def replace_versions(work_package, kind, version_ids)
        existing = work_package.work_package_versions.where(kind:).pluck(:version_id)

        to_remove = existing - version_ids
        to_add    = version_ids - existing

        # remove associations that are not present in the new list of versions
        work_package.work_package_versions.where(kind:, version_id: to_remove).delete_all if to_remove.any?
        # add new associations that were not already there
        work_package.work_package_versions.insert_all(to_add.map { |vid| { version_id: vid, kind: } }) if to_add.any?
      end
    end
  end
end
