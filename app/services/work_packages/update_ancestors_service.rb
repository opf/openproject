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
      # Derived estimated hours and Derived remaining hours need to be
      # calculated before the Derived done ratio below since the
      # aggregation depends on both derived fields.
      # Changes in any of these, also warrant a recalculation of
      # the Derived done ratio.
      #
      # Changes to estimated hours also warrant a recalculation of
      # derived done ratios in the work package's ancestry as the
      # derived estimated hours would affect the derived done ratio
      # or the derived remaining hours, depending on the % Complete mode
      # currently active.
      #
      %i[estimated_hours remaining_hours status status_id] => :derive_total_estimated_and_remaining_hours,
      %i[estimated_hours remaining_hours done_ratio status status_id] => :derive_done_ratio,
      %i[ignore_non_working_days] => :derive_ignore_non_working_days
    }.each do |derivative_attributes, method|
      if attributes.intersect?(derivative_attributes + %i[parent parent_id])
        send(method, work_package, loader)
      end
    end
  end

  def set_journal_note(work_packages)
    work_packages.each do |wp|
      wp.journal_notes = I18n.t("work_package.updated_automatically_by_child_changes", child: "##{initiator_work_package.id}")
    end
  end

  def derive_done_ratio(ancestor, loader)
    ancestor.derived_done_ratio = compute_derived_done_ratio(ancestor, loader)
  end

  def compute_derived_done_ratio(work_package, loader)
    return if work_package.derived_estimated_hours.nil? || work_package.derived_remaining_hours.nil?
    return if work_package.derived_estimated_hours.zero?
    return if no_children?(work_package, loader)

    work_done = (work_package.derived_estimated_hours - work_package.derived_remaining_hours)
    progress = (work_done.to_f / work_package.derived_estimated_hours) * 100
    progress.round
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

  def derive_total_estimated_and_remaining_hours(work_package, loader)
    work_package.derived_estimated_hours = derive_total(work_package, :estimated_hours, loader)
    work_package.derived_remaining_hours = derive_total(work_package, :remaining_hours, loader)
  end

  def derive_total(work_package, attribute, loader)
    return if no_children?(work_package, loader)

    work_packages = [work_package] + loader.descendants_of(work_package)
    values = work_packages
      .filter(&:included_in_totals_calculation?)
      .filter_map(&attribute)
    return if values.empty?

    values.sum.to_f
  end

  def no_children?(work_package, loader)
    loader.descendants_of(work_package).none?
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
