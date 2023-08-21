#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class WorkPackages::UpdateAncestorsService
  attr_accessor :user,
                :work_package

  def initialize(user:, work_package:)
    self.user = user
    self.work_package = work_package
  end

  def call(attributes)
    modified = update_current_and_former_ancestors(attributes)

    set_journal_note(modified)

    # Do not send notification for parent updates
    success = Journal::NotificationConfiguration.with(false) do
      modified.all? { |wp| wp.save(validate: false) }
    end

    result = ServiceResult.new(success:, result: work_package)

    modified.each do |wp|
      result.add_dependent!(ServiceResult.new(success: !wp.changed?, result: wp))
    end

    result
  end

  private

  def update_current_and_former_ancestors(attributes)
    WorkPackages::UpdateAncestors::Loader
      .new(work_package, (%i(parent_id parent) & attributes).any?)
      .select do |ancestor, loader|
        inherit_attributes(ancestor, loader, attributes)

        ancestor.changed?
      end
  end

  def inherit_attributes(ancestor, loader, attributes)
    return unless attributes_justify_inheritance?(attributes)

    # Estimated hours need to be calculated before the done_ratio below.
    # The aggregation only depends on estimated hours.
    derive_estimated_hours(ancestor, loader) if inherit?(attributes, :estimated_hours)

    # Progress (done_ratio or also: percentDone) depends on both
    # the completion of sub-WPs, as well as the estimated hours
    # as a weight factor. So changes in estimated hours also have
    # to trigger a recalculation of done_ratio.
    inherit_done_ratio(ancestor, loader) if inherit?(attributes, :done_ratio) || inherit?(attributes, :estimated_hours)

    inherit_ignore_non_working_days(ancestor, loader) if inherit?(attributes, :ignore_non_working_days)
  end

  def inherit?(attributes, attribute)
    ([attribute, :parent, :parent_id] & attributes).any?
  end

  def set_journal_note(work_packages)
    work_packages.each do |wp|
      wp.journal_notes = I18n.t('work_package.updated_automatically_by_child_changes', child: "##{work_package.id}")
    end
  end

  def inherit_done_ratio(ancestor, loader)
    return if WorkPackage.done_ratio_disabled?

    return if WorkPackage.use_status_for_done_ratio? && ancestor.status && ancestor.status.default_done_ratio

    # done ratio = weighted average ratio of leaves
    ancestor.done_ratio = (aggregate_done_ratio(ancestor, loader) || 0).round
  end

  # Sets the ignore_non_working_days to true if any ancestor has its value set to true.
  # If there is no value returned from the descendants, that means that the work package in
  # question no longer has a descendant. But since we are in the service going up the ancestor chain,
  # such a work package is the former parent. The property of such a work package is reset to `false`.
  def inherit_ignore_non_working_days(work_package, loader)
    return if work_package.schedule_manually

    descendant_value = ignore_non_working_days_of_descendants(work_package, loader)

    if descendant_value.nil?
      descendant_value = work_package.ignore_non_working_days
    end

    work_package.ignore_non_working_days = descendant_value
  end

  ##
  # done ratio = weighted average ratio of leaves
  def aggregate_done_ratio(work_package, loader)
    leaves = loader.leaves_of(work_package)

    leaves_count = leaves.size

    if leaves_count.positive?
      average = average_estimated_hours(leaves)
      progress = done_ratio_sum(leaves, average) / (average * leaves_count)

      progress.round(2)
    end
  end

  def average_estimated_hours(leaves)
    # 0 and nil shall be considered the same for estimated hours
    sum = all_estimated_hours(leaves).sum.to_f
    count = all_estimated_hours(leaves).count

    count = 1 if count.zero?

    average = sum / count

    average.zero? ? 1 : average
  end

  def done_ratio_sum(leaves, average_estimated_hours)
    # Do not take into account estimated_hours when it is either nil or set to 0.0
    summands = leaves.map do |leaf|
      estimated_hours = if leaf.estimated_hours.to_f.positive?
                          leaf.estimated_hours
                        else
                          average_estimated_hours
                        end

      done_ratio = if leaf.closed?
                     100
                   else
                     leaf.done_ratio || 0
                   end

      estimated_hours * done_ratio
    end

    summands.sum
  end

  def derive_estimated_hours(work_package, loader)
    descendants = loader.descendants_of(work_package)

    work_package.derived_estimated_hours = not_zero(all_estimated_hours(descendants).sum.to_f)
  end

  def not_zero(value)
    value unless value.zero?
  end

  def all_estimated_hours(work_packages)
    work_packages
      .map(&:estimated_hours)
      .reject { |hours| hours.to_f.zero? }
  end

  def attributes_justify_inheritance?(attributes)
    (%i(estimated_hours done_ratio parent parent_id status status_id ignore_non_working_days) & attributes).any?
  end

  def ignore_non_working_days_of_descendants(ancestor, loader)
    children = loader
                 .children_of(ancestor)
                 .reject(&:schedule_manually)

    if children.any?
      children.any?(&:ignore_non_working_days)
    end
  end
end
