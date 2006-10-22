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

class Project < ActiveRecord::Base
  has_many :versions, :dependent => true, :order => "versions.effective_date DESC, versions.name DESC"
  has_many :members, :dependent => true
  has_many :users, :through => :members
  has_many :custom_values, :dependent => true, :as => :customized
  has_many :issues, :dependent => true, :order => "issues.created_on DESC", :include => :status
  has_many :documents, :dependent => true
  has_many :news, :dependent => true, :include => :author
  has_many :issue_categories, :dependent => true, :order => "issue_categories.name"
  has_and_belongs_to_many :custom_fields, :class_name => 'IssueCustomField', :join_table => 'custom_fields_projects', :association_foreign_key => 'custom_field_id'
  acts_as_tree :order => "name", :counter_cache => true

  validates_presence_of :name, :description
  validates_uniqueness_of :name
  validates_associated :custom_values, :on => :update

  # returns 5 last created projects
  def self.latest
    find(:all, :limit => 5, :order => "created_on DESC")	
  end	

  # Returns an array of all custom fields enabled for project issues
  # (explictly associated custom fields and custom fields enabled for all projects)
  def custom_fields_for_issues(tracker)
    tracker.custom_fields.find(:all, :include => :projects, 
                               :conditions => ["is_for_all=? or project_id=?", true, self.id])
    #(CustomField.for_all + custom_fields).uniq
  end
  
  def all_custom_fields
    @all_custom_fields ||= IssueCustomField.find(:all, :include => :projects, 
                               :conditions => ["is_for_all=? or project_id=?", true, self.id])
  end

protected
  def validate
    errors.add(parent_id, " must be a root project") if parent and parent.parent
    errors.add_to_base("A project with subprojects can't be a subproject") if parent and projects_count > 0
  end
end
