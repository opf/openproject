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
  self.allowed_children = %w[ResourceUserCard ResourceWorkPackageList ResourceWorkPackageTimeline]

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

  # resource planner must belong to a project and a user
  validates :principal, :project,
            presence: true

  validate :end_date_after_start_date

  include ResourceManagement::Categorized

  def visible?(user)
    return false if project.nil?
    return false unless user.allowed_in_project?(:view_resource_planners, project)

    public? || principal == user
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date > start_date

    errors.add :end_date, :greater_than_start_date
  end
end
