#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
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

    # Do not send notification for parent updates
    success = Journal::NotificationConfiguration.with(false) do
      modified.all? { |wp| wp.save(validate: false) }
    end

    result = ServiceResult.new(success: success, result: work_package)

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
    return [] unless (%i(parent_id parent) & attributes).any? && previous_parent_id

    parent = WorkPackage.find(previous_parent_id)

    ([parent] + parent.ancestors).each do |ancestor|
      inherit_attributes!(ancestor)
    end.select(&:changed?)
  end

  def inherit_attributes!(ancestor)
    # pass :parent to force update of all inherited attributes
    inherit_attributes(ancestor, %i(parent))
  end

  def inherit_attributes(ancestor, attributes)
    return unless attributes_justify_inheritance?(attributes)

    derive_estimated_hours(ancestor) if inherit?(attributes, :estimated_hours)
    inherit_done_ratio(ancestor) if inherit?(attributes, :done_ratio)
  end

  def inherit?(attributes, attribute)
    ([attribute, :parent, :parent_id] & attributes).any?
  end

  def set_journal_note(work_packages)
    work_packages.each do |wp|
      wp.journal_notes = I18n.t('work_package.updated_automatically_by_child_changes', child: "##{work_package.id}")
    end
  end

  def inherit_done_ratio(ancestor)
    return if WorkPackage.done_ratio_disabled?

    return if WorkPackage.use_status_for_done_ratio? && ancestor.status && ancestor.status.default_done_ratio

    # done ratio = weighted average ratio of leaves
    ratio = aggregate_done_ratio(ancestor)

    if ratio
      ancestor.done_ratio = ratio.round
    end
  end

  ##
  # done ratio = weighted average ratio of leaves
  def aggregate_done_ratio(work_package)
    leaves = leaves_for_work_package(work_package)

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

  def derive_estimated_hours(work_package)
    descendants = descendants_for_work_package(work_package)

    work_package.derived_estimated_hours = not_zero(all_estimated_hours(descendants).sum.to_f)
  end

  def descendants_for_work_package(work_package)
    @descendants ||= Hash.new do |hash, wp|
      hash[wp] = related_for_work_package(wp, :descendants)
    end

    @descendants[work_package]
  end

  def leaves_for_work_package(work_package)
    @leaves ||= Hash.new do |hash, wp|
      hash[wp] = related_for_work_package(wp, :leaves).each do |leaf|
        # Mimick work package by implementing the closed? interface
        leaf.send(:'closed?=', leaf.is_closed)
      end
    end

    @leaves[work_package]
  end

  def related_for_work_package(work_package, relation_type)
    scope = work_package
            .send(relation_type)

    if send("#{relation_type}_joins")
      scope = scope.joins(send("#{relation_type}_joins"))
    end

    scope
      .pluck(*send("selected_#{relation_type}_attributes"))
      .map { |p| OpenStruct.new(send("selected_#{relation_type}_attributes").zip(p).to_h) }
  end

  def not_zero(value)
    value unless value.zero?
  end

  def all_estimated_hours(work_packages)
    work_packages
      .map(&:estimated_hours)
      .reject { |hours| hours.to_f.zero? }
  end

  ##
  # Get the previous parent ID
  # This could either be +parent_id_was+ if parent was changed
  # (when work_package was saved/destroyed)
  # Or the set parent before saving
  def previous_parent_id
    if work_package.parent_id.nil? && work_package.parent_id_was
      work_package.parent_id_was
    else
      previous_change_parent_id
    end
  end

  def previous_change_parent_id
    previous = work_package.previous_changes

    previous_parent_changes = (previous[:parent_id] || previous[:parent])

    previous_parent_changes ? previous_parent_changes.first : nil
  end

  def attributes_justify_inheritance?(attributes)
    (%i(estimated_hours done_ratio parent parent_id status status_id) & attributes).any?
  end

  def selected_descendants_attributes
    # By having the id in here, we can avoid DISTINCT queries sqashing duplicate values
    %i(id estimated_hours)
  end

  def descendants_joins
    nil
  end

  def selected_leaves_attributes
    %i(id done_ratio derived_estimated_hours estimated_hours is_closed)
  end

  def leaves_joins
    :status
  end
end
