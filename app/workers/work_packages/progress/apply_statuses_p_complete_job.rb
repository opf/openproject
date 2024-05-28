# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class WorkPackages::Progress::ApplyStatusesPCompleteJob < WorkPackages::Progress::Job
  VALID_CAUSE_TYPES = %w[
    progress_mode_changed_to_status_based
    status_p_complete_changed
  ].freeze

  # Updates % complete and remaining work of all work packages after a status %
  # complete value has been changed or the progress calculation mode was set to
  # status-based.
  #
  # It creates a journal entry with the System user describing the change.
  #
  # @param status_name [String] The cause of the update to be put in the journal
  #   entry. Must be one of `VALID_CAUSE_TYPES`.
  # @param status_name [String] The name of the status to apply.
  # @param status_id [Integer] The ID of the status to apply. Not used
  #   currently, but here in case we need it in a later version.
  # @param change [Object] The change object containing an array of [old, new]
  #   values of the change.
  # @return [void]
  def perform(cause_type:, status_name: nil, status_id: nil, change: nil)
    return if WorkPackage.use_field_for_done_ratio?

    journal_cause = journal_cause_from(cause_type, status_name:, status_id:, change:)

    with_temporary_progress_table do
      set_p_complete_from_status
      derive_remaining_work_from_work_and_p_complete
      update_totals

      copy_progress_values_to_work_packages_and_update_journals(journal_cause)
    end
  end

  private

  def journal_cause_from(cause_type, status_name:, status_id:, change:)
    if VALID_CAUSE_TYPES.exclude?(cause_type)
      raise ArgumentError, "Invalid cause type #{cause_type.inspect}. " \
                           "Valid values are #{VALID_CAUSE_TYPES.inspect}"
    end

    case cause_type
    when "progress_mode_changed_to_status_based"
      { type: cause_type }
    when "status_p_complete_changed"
      raise ArgumentError, "status_name must be provided" if status_name.blank?
      raise ArgumentError, "status_id must be provided" if status_id.nil?
      raise ArgumentError, "change must be provided" if change.nil?

      { type: cause_type, status_name:, status_id:, status_p_complete_change: change }
    else
      raise "Unable to handle cause type #{cause_type.inspect}"
    end
  end
end
