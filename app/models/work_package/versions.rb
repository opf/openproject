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
    # Deprecated single-version column, kept in sync with the first target
    # version (see #update_legacy_version_field). Can be dropped once all
    # subsystems read target_versions instead.
    belongs_to :version, optional: true

    has_many :work_package_versions, dependent: :delete_all
    has_many :versions, through: :work_package_versions, source: :version
    has_many :target_versions,
             -> { where(work_package_versions: { kind: "target" }) },
             through: :work_package_versions, source: :version
    has_many :observed_in_versions,
             -> { where(work_package_versions: { kind: "observed_in" }) },
             through: :work_package_versions, source: :version

    scope :without_version, -> {
      where(version_id: nil)
    }

    # Must be registered before `save_journals` (WorkPackage::Journalized) so
    # that the journal snapshot sees the current version sets in the database.
    after_save :persist_version_associations

    attr_accessor :target_version_ids_replacements,
                  :observed_in_version_ids_replacements
  end

  class_methods do
    # Unassigns work packages from +version+ if it's no longer shared with
    # the work package's project
    def update_versions_from_sharing_change(version)
      # Update work packages assigned to the version
      update_versions(["#{WorkPackage.table_name}.version_id = ?", version.id])
    end

    # Unassigns work packages from versions that are no longer shared
    # after +project+ was moved
    def update_versions_from_hierarchy_change(project)
      moved_project_ids = project.self_and_descendants.reload.map(&:id)
      # Update work packages of the moved projects and work packages assigned
      # to a version of a moved project
      update_versions(
        ["#{Version.table_name}.project_id IN (?) OR #{WorkPackage.table_name}.project_id IN (?)",
         moved_project_ids,
         moved_project_ids]
      )
    end

    private

    def having_version_from_other_project
      where(
        "#{WorkPackage.table_name}.version_id IS NOT NULL" +
        " AND #{WorkPackage.table_name}.project_id <> #{Version.table_name}.project_id" +
        " AND #{Version.table_name}.sharing <> 'system'"
      )
    end

    # Update work packages so their versions are not pointing to a
    # version that is not shared with the work package's project
    def update_versions(conditions = nil) # rubocop:disable Metrics/AbcSize
      # Only need to update work packages with a version from
      # a different project and that is not systemwide shared
      having_version_from_other_project
        .where(conditions)
        .includes(:project, :version)
        .references(:versions).find_each do |work_package|
        next if work_package.project.nil? || work_package.version.nil?

        unless work_package.project.shared_versions.include?(work_package.version)
          # this path clears version_id without going through the services,
          # so we need to manually drop the matching target association here too.
          work_package.target_versions.delete(work_package.version)
          work_package.version = nil
          unless work_package.save
            Rails.logger.error "Failed to clear version on work package ##{work_package.id}: " \
                               "#{work_package.errors.full_messages.to_sentence}"
          end
        end
      end
    end
  end

  # Versions that the work_package can be assigned to
  # A work_package can be assigned to:
  #   * any open, shared version of the project the wp belongs to
  #   * the version it was already assigned to
  #     (to make sure, that you can still update closed tickets)
  #   * for custom fields only_open: false can be used, if the CF is configured so
  def assignable_versions(only_open: true)
    if only_open
      @assignable_versions ||= begin
        current_version = version_id_changed? ? Version.find_by(id: version_id_was) : version
        ((project&.assignable_versions || []) + [current_version]).compact.uniq
      end
    else
      # The called method memoizes the result, no need to memoize it here.
      project&.assignable_versions(only_open: false)
    end
  end

  # The *_ids_replacements accessors behave according to these rules:
  # - when nil (the default) - leave the existing associations untouched
  # - when [] - clear the association
  # - when [<version ids>] - replace the existing set with exactly these
  # Consequently, nil vs. non-nil tells us whether an override was requested
  # at all.
  def override_target_versions? = !target_version_ids_replacements.nil?
  def override_observed_in_versions? = !observed_in_version_ids_replacements.nil?

  # returns pending replacements if they are present, or the association itself otherwise
  def effective_target_versions
    effective_versions(target_versions, target_version_ids_replacements)
  end

  def effective_observed_in_versions
    effective_versions(observed_in_versions, observed_in_version_ids_replacements)
  end

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

  def effective_versions(association, replacement_ids)
    return association if replacement_ids.nil?

    versions_by_id = Version.where(id: replacement_ids).index_by(&:id)
    replacement_ids.filter_map { |id| versions_by_id[id] }
  end

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

    clear_version_overrides
  end

  # Overrides are consumed by exactly one save. Left in place, they would be
  # re-applied by any later save of the same instance, clobbering version
  # changes made in between, and a stale system mark would exempt a later
  # user-requested override from the permission check.
  def clear_version_overrides
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
