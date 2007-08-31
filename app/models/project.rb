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
  # Project statuses
  STATUS_ACTIVE     = 1
  STATUS_ARCHIVED   = 9
  
  has_many :members, :dependent => :delete_all, :include => :user, :conditions => "#{User.table_name}.status=#{User::STATUS_ACTIVE}"
  has_many :users, :through => :members
  has_many :custom_values, :dependent => :delete_all, :as => :customized
  has_many :issues, :dependent => :destroy, :order => "#{Issue.table_name}.created_on DESC", :include => [:status, :tracker]
  has_many :issue_changes, :through => :issues, :source => :journals
  has_many :versions, :dependent => :destroy, :order => "#{Version.table_name}.effective_date DESC, #{Version.table_name}.name DESC"
  has_many :time_entries, :dependent => :delete_all
  has_many :queries, :dependent => :delete_all
  has_many :documents, :dependent => :destroy
  has_many :news, :dependent => :delete_all, :include => :author
  has_many :issue_categories, :dependent => :delete_all, :order => "#{IssueCategory.table_name}.name"
  has_many :boards, :order => "position ASC"
  has_one :repository, :dependent => :destroy
  has_one :wiki, :dependent => :destroy
  has_and_belongs_to_many :custom_fields, :class_name => 'IssueCustomField', :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}", :association_foreign_key => 'custom_field_id'
  acts_as_tree :order => "name", :counter_cache => true
  
  attr_protected :status
  
  validates_presence_of :name, :description, :identifier
  validates_uniqueness_of :name, :identifier
  validates_associated :custom_values, :on => :update
  validates_associated :repository, :wiki
  validates_length_of :name, :maximum => 30
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i
  validates_length_of :description, :maximum => 255
  validates_length_of :homepage, :maximum => 30
  validates_length_of :identifier, :in => 3..12
  validates_format_of :identifier, :with => /^[a-z0-9\-]*$/
  
  def identifier=(identifier)
    super unless identifier_frozen?
  end
  
  def identifier_frozen?
    errors[:identifier].nil? && !(new_record? || identifier.blank?)
  end
  
  def issues_with_subprojects(include_subprojects=false)
    conditions = nil
    if include_subprojects && !active_children.empty?
      ids = [id] + active_children.collect {|c| c.id}
      conditions = ["#{Issue.table_name}.project_id IN (#{ids.join(',')})"]
    end
    conditions ||= ["#{Issue.table_name}.project_id = ?", id]
    Issue.with_scope :find => { :conditions => conditions } do 
      yield
    end 
  end
  
  # returns latest created projects
  # non public projects will be returned only if user is a member of those
  def self.latest(user=nil, count=5)
    find(:all, :limit => count, :conditions => visible_by(user), :order => "created_on DESC")	
  end	

  def self.visible_by(user=nil)
    if user && user.admin?
      return "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
    elsif user && user.memberships.any?
      return "#{Project.table_name}.status=#{Project::STATUS_ACTIVE} AND (#{Project.table_name}.is_public = #{connection.quoted_true} or #{Project.table_name}.id IN (#{user.memberships.collect{|m| m.project_id}.join(',')}))"
    else
      return "#{Project.table_name}.status=#{Project::STATUS_ACTIVE} AND #{Project.table_name}.is_public = #{connection.quoted_true}"
    end
  end
  
  def active?
    self.status == STATUS_ACTIVE
  end
  
  def archive
    # Archive subprojects if any
    children.each do |subproject|
      subproject.archive
    end
    update_attribute :status, STATUS_ARCHIVED
  end
  
  def unarchive
    return false if parent && !parent.active?
    update_attribute :status, STATUS_ACTIVE
  end
  
  def active_children
    children.select {|child| child.active?}
  end
  
  # Returns an array of all custom fields enabled for project issues
  # (explictly associated custom fields and custom fields enabled for all projects)
  def custom_fields_for_issues(tracker)
    all_custom_fields.select {|c| tracker.custom_fields.include? c }
  end
  
  def all_custom_fields
    @all_custom_fields ||= (IssueCustomField.for_all + custom_fields).uniq
  end

protected
  def validate
    errors.add(parent_id, " must be a root project") if parent and parent.parent
    errors.add_to_base("A project with subprojects can't be a subproject") if parent and children.size > 0
  end
end
