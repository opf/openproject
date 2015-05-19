#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class TimeEntry < ActiveRecord::Base
  include Redmine::SafeAttributes
  # could have used polymorphic association
  # project association here allows easy loading of time entries at project level with one database trip
  belongs_to :project
  belongs_to :work_package
  belongs_to :user
  belongs_to :activity, class_name: 'TimeEntryActivity', foreign_key: 'activity_id'

  attr_protected :project_id, :user_id, :tyear, :tmonth, :tweek

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

  scope :visible, lambda {|*args|
                    {
                      include: :project,
                      conditions: Project.allowed_to_condition(args.first || User.current, :view_time_entries)
                    }}

  scope :on_work_packages, ->(work_packages) { where(work_package_id: work_packages) }

  after_initialize :set_default_activity
  before_validation :set_default_project

  safe_attributes 'hours', 'comments', 'work_package_id', 'activity_id', 'spent_on', 'custom_field_values'

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
    scope.minimum(:spent_on, include: :project)
  end

  def self.latest_date_for_project(project = nil)
    scope = TimeEntry.visible(User.current)
    scope = scope.where(project_id: project.hierarchy.map(&:id)) if project
    scope.maximum(:spent_on, include: :project)
  end

  private

  def validate_hours_are_in_range
    errors.add :hours, :invalid if hours && (hours < 0 || hours >= 1000)
  end

  def validate_project_is_set
    errors.add :project_id, :invalid if project.nil?
  end

  def validate_consistency_of_work_package_id
    errors.add :work_package_id, :invalid if (work_package_id && !work_package) || (work_package && project != work_package.project)
  end
end
