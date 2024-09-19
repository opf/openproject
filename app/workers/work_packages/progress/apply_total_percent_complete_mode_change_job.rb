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

  attr_reader :cause_type, :old_mode, :new_mode

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
  # @param [String] old_mode The previous total percent complete mode
  # @param [String] new_mode The new total percent complete mode
  # @return [void]
  def perform(cause_type:, old_mode:, new_mode:)
    @cause_type = cause_type
    @old_mode = old_mode
    @new_mode = new_mode

    with_temporary_total_percent_complete_table do
      update_total_percent_complete
      copy_total_percent_complete_values_to_work_packages_and_update_journals(journal_cause)
    end
  end

  private

  def update_total_percent_complete
    case new_mode
    when "work_weighted_average"
      update_work_weighted_average
    when "simple_average"
      update_simple_average
    else
      raise ArgumentError, "Invalid total percent complete mode: #{new_mode}"
    end
  end

  def update_work_weighted_average
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET total_p_complete = CASE
        WHEN total_work IS NULL OR total_remaining_work IS NULL THEN NULL
        WHEN total_work = 0 THEN NULL
        ELSE ROUND(
          ((total_work - total_remaining_work)::float / total_work) * 100
        )
      END
      WHERE id IN (
        SELECT ancestor_id
        FROM work_package_hierarchies
        GROUP BY ancestor_id
        HAVING MAX(generations) > 0
      )
    SQL
  end

  def update_simple_average
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET derived_done_ratio = CASE
        WHEN avg_ratios.avg_done_ratio IS NOT NULL THEN ROUND(avg_ratios.avg_done_ratio)
        ELSE done_ratio
      END
      FROM (
        SELECT wp_tree.ancestor_id AS id,
               AVG(CASE
                 WHEN wp_tree.generations = 1 THEN COALESCE(wp_progress.done_ratio, 0)
                 ELSE NULL
               END) AS avg_done_ratio
        FROM work_package_hierarchies wp_tree
          LEFT JOIN temp_wp_progress_values wp_progress ON wp_tree.descendant_id = wp_progress.id
          LEFT JOIN statuses ON wp_progress.status_id = statuses.id
        WHERE statuses.excluded_from_totals = FALSE
        GROUP BY wp_tree.ancestor_id
      ) avg_ratios
      WHERE temp_wp_progress_values.id = avg_ratios.id
      AND temp_wp_progress_values.id IN (
        SELECT ancestor_id AS id
        FROM work_package_hierarchies
        GROUP BY id
        HAVING MAX(generations) > 0
      )
    SQL
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
