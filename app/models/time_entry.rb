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

class TimeEntry < ActiveRecord::Base
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

  validate :validate_hours_are_in_range
  validate :validate_project_is_set
  validate :validate_consistency_of_work_package_id


  scope :on_work_packages, ->(work_packages) { where(work_package_id: work_packages) }

  after_initialize :set_default_activity
  before_validation :set_default_project

  def self.visible(*args)
    # TODO: check whether the visibility should also be influenced by the work
    # package the time entry is assigned to.  Currently a work package can
    # switch projects. But as the time entry is still part of it's original
    # project, it is unclear, whether the time entry is actually visible if the
    # user lacks the view_work_packages permission in the moved to project.
    joins(:project)
      .merge(Project.allowed_to(args.first || User.current, :view_time_entries))
  end

  def set_default_activity
    if new_record? && activity.nil?
      if default_activity = TimeEntryActivity.default
        self.activity_id = default_activity.id
      end
      self.hours = nil if hours == 0
    end
  end

  def set_default_project
    self.project ||= work_package.project if work_package
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

  def authoritativ_activity
    if activity.shared?
      activity
    else
      activity.root
    end
  end

  private

  def validate_hours_are_in_range
    errors.add :hours, :invalid if hours && hours < 0
  end

  def validate_project_is_set
    errors.add :project_id, :invalid if project.nil?
  end

  def validate_consistency_of_work_package_id
    errors.add :work_package_id, :invalid if (work_package_id && !work_package) || (work_package && project != work_package.project)
  end
end
