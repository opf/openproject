# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class Workflow < ActiveRecord::Base
  belongs_to :role
  belongs_to :old_status, :class_name => 'IssueStatus', :foreign_key => 'old_status_id'
  belongs_to :new_status, :class_name => 'IssueStatus', :foreign_key => 'new_status_id'

  validates_presence_of :role, :old_status, :new_status
  
  # Returns workflow transitions count by tracker and role
  def self.count_by_tracker_and_role
    counts = connection.select_all("SELECT role_id, tracker_id, count(id) AS c FROM #{Workflow.table_name} GROUP BY role_id, tracker_id")
    roles = Role.find(:all, :order => 'builtin, position')
    trackers = Tracker.find(:all, :order => 'position')
    
    result = []
    trackers.each do |tracker|
      t = []
      roles.each do |role|
        row = counts.detect {|c| c['role_id'].to_s == role.id.to_s && c['tracker_id'].to_s == tracker.id.to_s}
        t << [role, (row.nil? ? 0 : row['c'].to_i)]
      end
      result << [tracker, t]
    end
    
    result
  end

  # Find potential statuses the user could be allowed to switch issues to
  def self.available_statuses(project, user=User.current)
    Workflow.find(:all,
                  :include => :new_status,
                  :conditions => {:role_id => user.roles_for_project(project).collect(&:id)}).
      collect(&:new_status).
      compact.
      uniq.
      sort
  end
  
  # Copies workflows from source to targets
  def self.copy(source_tracker, source_role, target_trackers, target_roles)
    unless source_tracker.is_a?(Tracker) || source_role.is_a?(Role)
      raise ArgumentError.new("source_tracker or source_role must be specified")
    end
    
    target_trackers = [target_trackers].flatten.compact
    target_roles = [target_roles].flatten.compact
    
    target_trackers = Tracker.all if target_trackers.empty?
    target_roles = Role.all if target_roles.empty?
    
    target_trackers.each do |target_tracker|
      target_roles.each do |target_role|
        copy_one(source_tracker || target_tracker,
                   source_role || target_role,
                   target_tracker,
                   target_role)
      end
    end
  end
  
  # Copies a single set of workflows from source to target
  def self.copy_one(source_tracker, source_role, target_tracker, target_role)
    unless source_tracker.is_a?(Tracker) && !source_tracker.new_record? &&
      source_role.is_a?(Role) && !source_role.new_record? &&
      target_tracker.is_a?(Tracker) && !target_tracker.new_record? &&
      target_role.is_a?(Role) && !target_role.new_record?
      
      raise ArgumentError.new("arguments can not be nil or unsaved objects")
    end
    
    if source_tracker == target_tracker && source_role == target_role
      false
    else
      transaction do
        delete_all :tracker_id => target_tracker.id, :role_id => target_role.id
        connection.insert "INSERT INTO #{Workflow.table_name} (tracker_id, role_id, old_status_id, new_status_id)" +
                          " SELECT #{target_tracker.id}, #{target_role.id}, old_status_id, new_status_id" +
                          " FROM #{Workflow.table_name}" +
                          " WHERE tracker_id = #{source_tracker.id} AND role_id = #{source_role.id}"
      end
      true
    end
  end
end
