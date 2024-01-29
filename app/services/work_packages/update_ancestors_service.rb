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

class WorkPackages::UpdateAncestorsService
  attr_accessor :user,
                :initiator_work_package

  def initialize(user:, work_package:)
    self.user = user
    self.initiator_work_package = work_package
  end

  def call(attributes)
    updated_work_packages = update_current_and_former_ancestors(attributes)

    set_journal_note(ancestors(updated_work_packages))
    success = save_updated_work_packages(updated_work_packages)

    result = ServiceResult.new(success:, result: initiator_work_package)

    ancestors(updated_work_packages).each do |wp|
      result.add_dependent!(ServiceResult.new(success: !wp.changed?, result: wp))
    end

    result
  end

  private

  def initiator?(work_package)
    work_package == initiator_work_package
  end

  def ancestors(work_packages)
    work_packages.reject { initiator?(_1) }
  end

  def update_current_and_former_ancestors(attributes)
    include_former_ancestors = attributes.intersect?(%i[parent_id parent])
    WorkPackages::UpdateAncestors::Loader
      .new(initiator_work_package, include_former_ancestors)
      .select do |ancestor, loader|
        derive_attributes(ancestor, loader, attributes)

        ancestor.changed?
      end
  end

  def save_updated_work_packages(updated_work_packages)
    updated_initiators, updated_ancestors = updated_work_packages.partition { initiator?(_1) }

    # Send notifications for initiator updates
    success = updated_initiators.all? { |wp| wp.save(validate: false) }
    # Do not send notifications for parent updates
    success &&= Journal::NotificationConfiguration.with(false) do
      updated_ancestors.all? { |wp| wp.save(validate: false) }
    end
    success
  end

  def derive_attributes(work_package, loader, attributes)
    return unless modified_attributes_justify_derivation?(attributes)

    {
      # Estimated hours need to be calculated before the done_ratio below.
      # The aggregation only depends on estimated hours.
      %i[estimated_hours] => :derive_estimated_hours,
      # Progress (done_ratio or also: percentDone) depends on both
      # the completion of sub-WPs, as well as the estimated hours
      # as a weight factor. So changes in estimated hours also have
      # to trigger a recalculation of done_ratio.
      %i[done_ratio estimated_hours status status_id] => :derive_done_ratio,
      %i[remaining_hours] => :derive_remaining_hours,
      %i[ignore_non_working_days] => :derive_ignore_non_working_days
    }.each do |derivative_attributes, method|
      if attributes.intersect?(derivative_attributes + %i[parent parent_id])
        send(method, work_package, loader)
      end
    end
  end

  def set_journal_note(work_packages)
    work_packages.each do |wp|
      wp.journal_notes = I18n.t('work_package.updated_automatically_by_child_changes', child: "##{initiator_work_package.id}")
    end
  end

  def derive_done_ratio(ancestor, loader)
    return if initiator?(ancestor)
    return if WorkPackage.done_ratio_disabled?

    return if WorkPackage.use_status_for_done_ratio? && ancestor.status && ancestor.status.default_done_ratio

    # done ratio = weighted average ratio of leaves
    ancestor.derived_done_ratio = (aggregate_done_ratio(ancestor, loader) || 0).round
  end

  # Sets the ignore_non_working_days to true if any descendant has its value set to true.
  # If there is no value returned from the descendants, that means that the work package in
  # question no longer has a descendant. But since we are in the service going up the ancestor chain,
  # such a work package is the former parent. The property of such a work package is reset to `false`.
  def derive_ignore_non_working_days(ancestor, loader)
    return if initiator?(ancestor)
    return if ancestor.schedule_manually

    descendant_value = ignore_non_working_days_of_descendants(ancestor, loader)

    if descendant_value.nil?
      descendant_value = ancestor.ignore_non_working_days
    end

    ancestor.ignore_non_working_days = descendant_value
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

    work_package.derived_estimated_hours = not_zero(all_estimated_hours([work_package] + descendants).sum.to_f)
  end

  def derive_remaining_hours(work_package, loader)
    descendants = loader.descendants_of(work_package)

    work_package.derived_remaining_hours = not_zero(all_remaining_hours([work_package] + descendants).sum.to_f)
  end

  def not_zero(value)
    value unless value.zero?
  end

  def all_estimated_hours(work_packages)
    work_packages
      .map(&:estimated_hours)
      .reject { |hours| hours.to_f.zero? }
  end

  def all_remaining_hours(work_packages)
    work_packages.map(&:remaining_hours).reject { |hours| hours.to_f.zero? }
  end

  def modified_attributes_justify_derivation?(attributes)
    attributes.intersect?(%i[
                            done_ratio
                            estimated_hours
                            ignore_non_working_days
                            parent parent_id
                            remaining_hours
                            status status_id
                          ])
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
