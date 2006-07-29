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

class Permission < ActiveRecord::Base
	has_and_belongs_to_many :roles
  
	validates_presence_of :controller, :action, :description
  
  GROUPS = {
    100 => "Project",
		200 => "Membres",
    300 => "Versions",
    400 => "Issue categories",
		1000 => "Issues",
		1100 => "News",
		1200 => "Documents",
    1300 => "Files",
	}.freeze
  
  @@cached_perms_for_public = nil
  @@cached_perms_for_roles = nil
  
 	def name
		self.controller + "/" + self.action
	end
  
  def group_id
    (self.sort / 100)*100
  end
  
  def self.allowed_to_public(action)
    @@cached_perms_for_public ||= find(:all, :conditions => ["is_public=?", true]).collect {|p| "#{p.controller}/#{p.action}"}
    @@cached_perms_for_public.include? action
  end
  
  def self.allowed_to_role(action, role)
    @@cached_perms_for_roles ||=
      begin
        perms = {}
        find(:all, :include => :roles).each {|p| perms.store "#{p.controller}/#{p.action}", p.roles.collect {|r| r.id } }
        perms
      end
    @@cached_perms_for_roles[action] and @@cached_perms_for_roles[action].include? role
  end
  
  def self.allowed_to_role_expired
    @@cached_perms_for_roles = nil
  end
end
