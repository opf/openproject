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

class WorkPackages::Progress::ApplyStatusesChangeJob < WorkPackages::Progress::Job
  VALID_CAUSE_TYPES = %w[
    progress_mode_changed_to_status_based
    status_changed
  ].freeze

  attr_reader :cause_type, :status_name, :status_id, :changes

  # Updates % complete and remaining work of all work packages after a status %
  # complete value has been changed or the progress calculation mode was set to
  # status-based.
  #
  # It creates a journal entry with the System user describing the changes.
  #
  # @param status_name [String] The cause of the update to be put in the journal
  #   entry. Must be one of `VALID_CAUSE_TYPES`.
  # @param status_name [String] The name of the status to apply.
  # @param status_id [Integer] The ID of the status to apply. Not used
  #   currently, but here in case we need it in a later version.
  # @param changes [Object] The changes object containing a map of array of
  #   [old, new] values of the change, for instance
  #   `{"default_done_ratio" => [20, 40], "excluded_from_totals" => [false, true]}`.
  # @return [void]
  def perform(cause_type:, status_name: nil, status_id: nil, changes: nil)
    @cause_type = cause_type
    @status_name = status_name
    @status_id = status_id
    @changes = changes

    with_temporary_progress_table do
      adjust_progress_values
      update_totals
      copy_progress_values_to_work_packages_and_update_journals(journal_cause)
    end
  end

  private

  def adjust_progress_values
    if WorkPackage.work_based_mode?
      clear_percent_complete_when_0h_work
    elsif WorkPackage.status_based_mode?
      set_p_complete_from_status
      if OpenProject::FeatureDecisions.percent_complete_edition_active?
        fix_remaining_work_set_with_100p_complete
        derive_unset_work_from_remaining_work_and_p_complete
      end
      derive_remaining_work_from_work_and_p_complete
    end
  end

  def journal_cause
    assert_valid_cause_type!

    @journal_cause ||=
      case cause_type
      when "progress_mode_changed_to_status_based"
        Journal::CausedByProgressModeChangedToStatusBased.new
      when "status_changed"
        assert_status_information_present!
        Journal::CausedByStatusChanged.new(
          status_name:,
          status_id:,
          status_changes: changes
        )
      else
        raise "Unable to handle cause type #{cause_type.inspect}"
      end
  end

  def assert_valid_cause_type!
    unless VALID_CAUSE_TYPES.include?(cause_type)
      raise ArgumentError, "Invalid cause type #{cause_type.inspect}. " \
                           "Valid values are #{VALID_CAUSE_TYPES.inspect}"
    end
  end

  def assert_status_information_present!
    if status_name.blank?
      raise ArgumentError, "status_name must be provided"
    end

    if status_id.nil?
      raise ArgumentError, "status_id must be provided"
    end

    if changes.nil?
      raise ArgumentError, "changes must be provided"
    end
  end

  def clear_percent_complete_when_0h_work
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET done_ratio = NULL
      WHERE estimated_hours = 0
    SQL
  end
end
