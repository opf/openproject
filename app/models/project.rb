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
  has_many :versions, :dependent => :destroy, :order => "versions.effective_date DESC, versions.name DESC"
  has_many :members, :dependent => :delete_all, :include => :user, :conditions => "users.status=#{User::STATUS_ACTIVE}"
  has_many :users, :through => :members
  has_many :custom_values, :dependent => :delete_all, :as => :customized
  has_many :issues, :dependent => :destroy, :order => "issues.created_on DESC", :include => [:status, :tracker]
  has_many :queries, :dependent => :delete_all
  has_many :documents, :dependent => :destroy
  has_many :news, :dependent => :delete_all, :include => :author
  has_many :issue_categories, :dependent => :delete_all, :order => "issue_categories.name"
  has_one :repository, :dependent => :destroy
  has_and_belongs_to_many :custom_fields, :class_name => 'IssueCustomField', :join_table => 'custom_fields_projects', :association_foreign_key => 'custom_field_id'
  acts_as_tree :order => "name", :counter_cache => true

  validates_presence_of :name, :description
  validates_uniqueness_of :name
  validates_associated :custom_values, :on => :update
  validates_associated :repository
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i

  # returns latest created projects
  # non public projects will be returned only if user is a member of those
  def self.latest(user=nil, count=5)
    find(:all, :limit => count, :conditions => visible_by(user), :order => "projects.created_on DESC")	
  end	

  def self.visible_by(user=nil)
    if user && !user.memberships.empty?
      return ["projects.is_public = ? or projects.id IN (#{user.memberships.collect{|m| m.project_id}.join(',')})", true]
    else
      return ["projects.is_public = ?", true]
    end
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
    errors.add_to_base("A project with subprojects can't be a subproject") if parent and children.size > 0
  end
end
