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

class Role < ActiveRecord::Base
  # Built-in roles
  BUILTIN_NON_MEMBER = 1
  BUILTIN_ANONYMOUS  = 2
  
  before_destroy :check_deletable
  has_many :workflows, :dependent => :delete_all do
    def copy(role)
      raise "Can not copy workflow from a #{role.class}" unless role.is_a?(Role)
      raise "Can not copy workflow from/to an unsaved role" if proxy_owner.new_record? || role.new_record?
      clear
      connection.insert "INSERT INTO workflows (tracker_id, old_status_id, new_status_id, role_id)" +
                        " SELECT tracker_id, old_status_id, new_status_id, #{proxy_owner.id}" +
                        " FROM workflows" +
                        " WHERE role_id = #{role.id}"
    end
  end
  
  has_many :members
  acts_as_list
  
  serialize :permissions
  attr_protected :builtin

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i

  def permissions
    read_attribute(:permissions) || []
  end
  
  def permissions=(perms)
    perms = perms.collect {|p| p.to_sym unless p.blank? }.compact if perms
    write_attribute(:permissions, perms)
  end
  
  def <=>(role)
    position <=> role.position
  end
  
  # Return true if the role is a builtin role
  def builtin?
    self.builtin != 0
  end
  
  # Return true if the role is a project member role
  def member?
    !self.builtin?
  end
  
  # Return true if role is allowed to do the specified action
  # action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  def allowed_to?(action)
    if action.is_a? Hash
      allowed_actions.include? "#{action[:controller]}/#{action[:action]}"
    else
      allowed_permissions.include? action
    end
  end
  
  # Return all the permissions that can be given to the role
  def setable_permissions
    setable_permissions = Redmine::AccessControl.permissions - Redmine::AccessControl.public_permissions
    setable_permissions -= Redmine::AccessControl.members_only_permissions if self.builtin == BUILTIN_NON_MEMBER
    setable_permissions -= Redmine::AccessControl.loggedin_only_permissions if self.builtin == BUILTIN_ANONYMOUS
    setable_permissions
  end

  # Find all the roles that can be given to a project member
  def self.find_all_givable
    find(:all, :conditions => {:builtin => 0}, :order => 'position')
  end

  # Return the builtin 'non member' role
  def self.non_member
    find(:first, :conditions => {:builtin => BUILTIN_NON_MEMBER}) || raise('Missing non-member builtin role.')
  end

  # Return the builtin 'anonymous' role 
  def self.anonymous
    find(:first, :conditions => {:builtin => BUILTIN_ANONYMOUS}) || raise('Missing anonymous builtin role.')
  end

  
private
  def allowed_permissions
    @allowed_permissions ||= permissions + Redmine::AccessControl.public_permissions.collect {|p| p.name}
  end

  def allowed_actions
    @actions_allowed ||= allowed_permissions.inject([]) { |actions, permission| actions += Redmine::AccessControl.allowed_actions(permission) }.flatten
  end
    
  def check_deletable
    raise "Can't delete role" if members.any?
    raise "Can't delete builtin role" if builtin?
  end
end
