# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

class TimeEntry < ActiveRecord::Base
  # could have used polymorphic association
  # project association here allows easy loading of time entries at project level with one database trip
  belongs_to :project
  belongs_to :issue
  belongs_to :user
  belongs_to :activity, :class_name => 'TimeEntryActivity', :foreign_key => 'activity_id'
  
  attr_protected :project_id, :user_id, :tyear, :tmonth, :tweek

  acts_as_customizable
  acts_as_event :title => Proc.new {|o| "#{l_hours(o.hours)} (#{(o.issue || o.project).event_title})"},
                :url => Proc.new {|o| {:controller => 'timelog', :action => 'details', :project_id => o.project, :issue_id => o.issue}},
                :author => :user,
                :description => :comments

  acts_as_activity_provider :timestamp => "#{table_name}.created_on",
                            :author_key => :user_id,
                            :find_options => {:include => :project} 

  validates_presence_of :user_id, :activity_id, :project_id, :hours, :spent_on
  validates_numericality_of :hours, :allow_nil => true, :message => :invalid
  validates_length_of :comments, :maximum => 255, :allow_nil => true

  def after_initialize
    if new_record? && self.activity.nil?
      if default_activity = TimeEntryActivity.default
        self.activity_id = default_activity.id
      end
      self.hours = nil if hours == 0
    end
  end
  
  def before_validation
    self.project = issue.project if issue && project.nil?
  end
  
  def validate
    errors.add :hours, :invalid if hours && (hours < 0 || hours >= 1000)
    errors.add :project_id, :invalid if project.nil?
    errors.add :issue_id, :invalid if (issue_id && !issue) || (issue && project!=issue.project)
  end
  
  def hours=(h)
    write_attribute :hours, (h.is_a?(String) ? (h.to_hours || h) : h)
  end
  
  # tyear, tmonth, tweek assigned where setting spent_on attributes
  # these attributes make time aggregations easier
  def spent_on=(date)
    super
    self.tyear = spent_on ? spent_on.year : nil
    self.tmonth = spent_on ? spent_on.month : nil
    self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
  end
  
  # Returns true if the time entry can be edited by usr, otherwise false
  def editable_by?(usr)
    (usr == user && usr.allowed_to?(:edit_own_time_entries, project)) || usr.allowed_to?(:edit_time_entries, project)
  end
  
  def self.visible_by(usr)
    with_scope(:find => { :conditions => Project.allowed_to_condition(usr, :view_time_entries) }) do
      yield
    end
  end

  def self.earilest_date_for_project(project=nil)
    finder_conditions = ARCondition.new(Project.allowed_to_condition(User.current, :view_time_entries))
    if project
      finder_conditions << ["project_id IN (?)", project.hierarchy.collect(&:id)]
    end
    TimeEntry.minimum(:spent_on, :include => :project, :conditions => finder_conditions.conditions)
  end

  def self.latest_date_for_project(project=nil)
    finder_conditions = ARCondition.new(Project.allowed_to_condition(User.current, :view_time_entries))
    if project
      finder_conditions << ["project_id IN (?)", project.hierarchy.collect(&:id)]
    end
    TimeEntry.maximum(:spent_on, :include => :project, :conditions => finder_conditions.conditions)
  end
end
