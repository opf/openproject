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

module WorkPackage::Versions
  extend ActiveSupport::Concern

  included do
    # Must be registered before `save_journals` (WorkPackage::Journalized) so
    # that the journal snapshot sees the current version sets in the database.
    after_save :persist_version_associations

    attr_accessor :target_version_ids_replacements,
                  :observed_in_version_ids_replacements
  end

  # The *_replacements accessors default to nil, which means "leave the existing
  # associations untouched". Once a caller assigns to them (even an empty array),
  # it signals intent to replace the whole set, so nil vs. non-nil is what tells
  # us whether an override was requested at all.
  def override_target_versions? = !target_version_ids_replacements.nil?
  def override_observed_in_versions? = !observed_in_version_ids_replacements.nil?

  # An override can also originate from the system, e.g. when versions that are
  # not shared with the (new) project are cleared on a project change. Such
  # overrides are marked here so that contracts don't attribute them to the
  # user (mirroring what change_by_system does for regular attributes).
  def mark_system_version_override(kind)
    system_version_overrides << kind.to_s
  end

  def system_version_override?(kind)
    system_version_overrides.include?(kind.to_s)
  end

  private

  def system_version_overrides
    @system_version_overrides ||= Set.new
  end

  # Two paths feed the "target" associations:
  #   * an explicit override (the *_replacements accessor was set) takes
  #     precedence and replaces the whole set.
  #   * otherwise, a plain change to version_id (the legacy single-version
  #     path) is mirrored into the associations so both stay consistent.
  #
  # Writing to version_id will be removed after all subsystems start using
  # target_versions instead
  def persist_version_associations
    if override_target_versions?
      replace_versions("target", target_version_ids_replacements)
      update_legacy_version_field
    elsif saved_change_to_version_id?
      replace_versions("target", Array(version_id))
    end

    if override_observed_in_versions?
      replace_versions("observed_in", observed_in_version_ids_replacements)
    end

    reset_version_overrides
  end

  # Overrides are consumed by exactly one save. Left in place, they would be
  # re-applied by any later save of the same instance, clobbering version
  # changes made in between, and a stale system mark would exempt a later
  # user-requested override from the permission check.
  def reset_version_overrides
    self.target_version_ids_replacements = nil
    self.observed_in_version_ids_replacements = nil
    system_version_overrides.clear
  end

  # Keeps the deprecated single version_id column in sync with the first
  # target version, so code still reading version_id sees a sensible value.
  # Can be dropped once the version_id column is removed.
  def update_legacy_version_field
    new_version_id = target_version_ids_replacements.first

    update_columns(version_id: new_version_id) unless version_id == new_version_id
  end

  # Sets the work package's associations of the given kind to exactly the
  # given version_ids.
  def replace_versions(kind, version_ids)
    existing = work_package_versions.where(kind:).pluck(:version_id)

    to_remove = existing - version_ids
    to_add    = version_ids - existing

    # remove associations that are not present in the new list of versions
    work_package_versions.where(kind:, version_id: to_remove).delete_all if to_remove.any?
    # add new associations that were not already there
    work_package_versions.insert_all(to_add.map { |vid| { version_id: vid, kind: } }) if to_add.any?
  end
end
