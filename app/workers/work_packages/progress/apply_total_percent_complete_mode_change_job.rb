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

class WorkPackages::Progress::ApplyTotalPercentCompleteModeChangeJob < WorkPackages::Progress::Job
  VALID_CAUSE_TYPES = %w[
    total_percent_complete_mode_changed_to_work_weighted_average
    total_percent_complete_mode_changed_to_simple_average
  ].freeze

  attr_reader :cause_type, :mode

  # Updates the total % complete of all work packages after the total
  # percent complete mode has been changed.
  #
  # It creates a journal entry with the System user describing the changes.
  #
  #
  # Updates the total % complete of all work packages after the total
  # percent complete mode has been changed.
  #
  # It creates a journal entry with the System user describing the changes.
  #
  # @param [String] cause_type The cause type of the change
  # @param [String] mode The new total percent complete mode
  # @return [void]
  def perform(cause_type:, mode:)
    @cause_type = cause_type
    @mode = mode

    with_temporary_total_percent_complete_table do
      update_total_percent_complete
      copy_total_percent_complete_values_to_work_packages_and_update_journals(journal_cause)
    end
  end

  private

  def update_total_percent_complete
    case mode
    when "work_weighted_average"
      update_total_percent_complete_in_work_weighted_average_mode
    when "simple_average"
      update_total_percent_complete_in_simple_average_mode
    else
      raise ArgumentError, "Invalid total percent complete mode: #{mode}"
    end
  end

  def journal_cause
    assert_valid_cause_type!

    @journal_cause ||=
      case cause_type
      when "total_percent_complete_mode_changed_to_work_weighted_average"
        Journal::CausedByTotalPercentCompleteModeChangedToWorkWeightedAverage.new
      when "total_percent_complete_mode_changed_to_simple_average"
        Journal::CausedByTotalPercentCompleteModeChangedToSimpleAverage.new
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
end
