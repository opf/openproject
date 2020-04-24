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

class TimeEntry < ApplicationRecord
  # could have used polymorphic association
  # project association here allows easy loading of time entries at project level with one database trip
  belongs_to :project
  belongs_to :work_package
  belongs_to :user
  belongs_to :activity, class_name: 'TimeEntryActivity', foreign_key: 'activity_id'

  acts_as_customizable

  acts_as_journalized

  acts_as_event title: Proc.new { |o| "#{l_hours(o.hours)} (#{o.project.event_title})" },
                url: Proc.new { |o| { controller: '/timelog', action: 'index', project_id: o.project, work_package_id: o.work_package } },
                datetime: :created_on,
                author: :user,
                description: :comments

  validates_presence_of :user_id, :activity_id, :project_id, :hours, :spent_on
  validates_numericality_of :hours, allow_nil: true, message: :invalid
  validates_length_of :comments, maximum: 255, allow_nil: true

  scope :on_work_packages, ->(work_packages) { where(work_package_id: work_packages) }

  def self.visible(*args)
    # TODO: check whether the visibility should also be influenced by the work
    # package the time entry is assigned to.  Currently a work package can
    # switch projects. But as the time entry is still part of it's original
    # project, it is unclear, whether the time entry is actually visible if the
    # user lacks the view_work_packages permission in the moved to project.
    joins(:project)
      .merge(Project.allowed_to(args.first || User.current, :view_time_entries))
  end

  def hours=(h)
    write_attribute :hours, (h.is_a?(String) ? (h.to_hours || h) : h)
  end

  # tyear, tmonth, tweek assigned where setting spent_on attributes
  # these attributes make time aggregations easier
  def spent_on=(date)
    super
    if spent_on.is_a?(Time)
      self.spent_on = spent_on.to_date
    end
    self.tyear = spent_on ? spent_on.year : nil
    self.tmonth = spent_on ? spent_on.month : nil
    self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
  end

  # Returns true if the time entry can be edited by usr, otherwise false
  def editable_by?(usr)
    (usr == user && usr.allowed_to?(:edit_own_time_entries, project)) || usr.allowed_to?(:edit_time_entries, project)
  end

  def self.earliest_date_for_project(project = nil)
    scope = TimeEntry.visible(User.current)
    scope = scope.where(project_id: project.hierarchy.map(&:id)) if project
    scope.includes(:project).minimum(:spent_on)
  end

  def self.latest_date_for_project(project = nil)
    scope = TimeEntry.visible(User.current)
    scope = scope.where(project_id: project.hierarchy.map(&:id)) if project
    scope.includes(:project).maximum(:spent_on)
  end
end
