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

class ResourcePlanner < PersistedView
  self.allowed_children = %w[
    ResourceWorkPackageTimeline
    ResourceUserTimeline
    ResourceWorkPackageList
    ResourceUserCard
  ]

  # Virtual attributes used by the new-planner form. They are not persisted on
  # the planner itself: `default_view_class_name` is consumed when creating the
  # initial child view, and `favorite` is consumed by `add_favoriting_user`.
  attr_accessor :default_view_class_name, :favorite

  store_attribute :options, :start_date, :date
  store_attribute :options, :end_date, :date
  store_attribute :options, :default_view_id, :integer

  # resource planner cannot be nested, queries are assigned to the sub-views
  validates :parent, absence: true
  validates :query, absence: true

  validates :principal, presence: true

  validate :end_date_after_start_date
  validate :dates_set_together

  include ResourceManagement::Categorized
  include ResourceManagement::DateRangeAttribute

  # Reaching the global section does not require the global permission: a member
  # of a project granting `view_resource_planners` keeps getting there, they just
  # find no global planners listed.
  def self.section_visible_to?(user)
    user.allowed_globally?(:view_global_resource_planners) ||
      user.allowed_in_any_project?(:view_resource_planners)
  end

  # `visible` only separates public from own planners, so the permission for the
  # scope the planner lives in has to be checked on top of it.
  def self.visible_to(user, project)
    return none unless viewable_by?(user, project)

    visible(user).where(project:)
  end

  def self.viewable_by?(user, project)
    if project
      user.allowed_in_project?(:view_resource_planners, project)
    else
      user.allowed_globally?(:view_global_resource_planners)
    end
  end

  # Whether to offer the allocate affordances at all. A global planner cannot
  # name a project up front, so holding the permission anywhere is enough to
  # start; the contract then checks it against the chosen work package's project.
  def self.allocatable_by?(user, project)
    if project
      user.allowed_in_project?(:allocate_user_resources, project)
    else
      user.allowed_in_any_project?(:allocate_user_resources)
    end
  end

  def self.public_manageable_by?(user, project)
    if project
      user.allowed_in_project?(:manage_public_resource_planners, project)
    else
      user.allowed_globally?(:manage_public_global_resource_planners)
    end
  end

  def global?
    project_id.nil?
  end

  def viewable_by?(user)
    self.class.viewable_by?(user, project)
  end

  def public_manageable_by?(user)
    self.class.public_manageable_by?(user, project)
  end

  def manageable_by?(user)
    (principal == user && viewable_by?(user)) || (public? && public_manageable_by?(user))
  end

  def visible?(user)
    return false unless viewable_by?(user)

    public? || principal == user
  end

  def work_package_count
    @work_package_count ||= distinct_child_count(ResourceManagement::WorkPackageSelection) do |view|
      view.work_packages.reorder(nil).ids
    end
  end

  def member_count
    @member_count ||= distinct_child_count(ResourceManagement::UserSelection) do |view|
      view.results&.ids || []
    end
  end

  private

  def distinct_child_count(selection_module)
    children.each_with_object(Set.new) do |view, ids|
      ids.merge(yield(view)) if view.is_a?(selection_module)
    end.size
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date > start_date

    errors.add :end_date, :greater_than_start_date
  end

  # The timeframe is optional, but it is picked as a range: it is either left
  # empty or both of its ends are given.
  def dates_set_together
    return if start_date.blank? == end_date.blank?

    if start_date.blank?
      errors.add :start_date, :required_with_end_date
    else
      errors.add :end_date, :required_with_start_date
    end
  end
end
