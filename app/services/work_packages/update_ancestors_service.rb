#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::UpdateAncestorsService
  attr_accessor :user,
                :work_package

  def initialize(user:, work_package:)
    self.user = user
    self.work_package = work_package
  end

  def call(attributes)
    modified = update_ancestors(attributes)
    modified += update_former_ancestors(attributes)

    set_journal_note(modified)

    result = ServiceResult.new(success: modified.all? { |wp| wp.save(validate: false) },
                               result: work_package)

    modified.each do |wp|
      result.add_dependent!(ServiceResult.new(success: !wp.changed?, result: wp))
    end

    result
  end

  private

  def update_ancestors(attributes)
    work_package.ancestors.includes(:status).select do |ancestor|
      inherit_attributes(ancestor, attributes)

      ancestor.changed?
    end
  end

  def update_former_ancestors(attributes)
    return [] unless (%i(parent_id parent) & attributes).any? && previous_parent_id(work_package)

    parent = WorkPackage.find(previous_parent_id(work_package))

    ([parent] + parent.ancestors).each do |ancestor|
      inherit_attributes(ancestor, %i(estimated_hours done_ratio))
    end.select(&:changed?)
  end

  def inherit_attributes(ancestor, attributes)
    return unless attributes_justify_inheritance?(attributes)

    leaves = ancestor
      .leaves
      .select(selected_leaf_attributes)
      .distinct(true) # Be explicit that this is a distinct (wrt ID) query
      .includes(:status).to_a

    inherit_done_ratio(ancestor, leaves)

    inherit_estimated_hours(ancestor, leaves)
  end

  def set_journal_note(work_packages)
    work_packages.each do |wp|
      wp.journal_notes = I18n.t('work_package.updated_automatically_by_child_changes', child: "##{work_package.id}")
    end
  end

  def inherit_done_ratio(ancestor, leaves)
    return if WorkPackage.done_ratio_disabled?

    return if WorkPackage.use_status_for_done_ratio? && ancestor.status && ancestor.status.default_done_ratio

    # done ratio = weighted average ratio of leaves
    ratio = aggregate_done_ratio(leaves)

    if ratio
      ancestor.done_ratio = ratio.round
    end
  end

  ##
  # done ratio = weighted average ratio of leaves
  def aggregate_done_ratio(leaves)
    leaves_count = leaves.size

    if leaves_count > 0
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
      estimated_hours = if leaf.estimated_hours.to_f > 0
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

  def inherit_estimated_hours(ancestor, leaves)
    ancestor.estimated_hours = all_estimated_hours(leaves).sum.to_f
    ancestor.estimated_hours = nil if ancestor.estimated_hours.zero?
  end

  def all_estimated_hours(work_packages)
    work_packages.map(&:estimated_hours).reject { |hours| hours.to_f.zero? }
  end

  def previous_parent_id(work_package)
    previous = work_package.previous_changes

    previous_parent_changes = (previous[:parent_id] || previous[:parent])

    previous_parent_changes ? previous_parent_changes.first : nil
  end

  def attributes_justify_inheritance?(attributes)
    (%i(estimated_hours done_ratio parent parent_id status status_id) & attributes).any?
  end

  def selected_leaf_attributes
    %i(id done_ratio estimated_hours status_id)
  end
end
