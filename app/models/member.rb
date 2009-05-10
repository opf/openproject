# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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

class Member < ActiveRecord::Base
  belongs_to :user
  has_many :member_roles, :dependent => :delete_all
  has_many :roles, :through => :member_roles
  belongs_to :project

  validates_presence_of :user, :project
  validates_uniqueness_of :user_id, :scope => :project_id
  
  def name
    self.user.name
  end
  
  # Sets user by login
  def user_login=(login)
    login = login.to_s
    unless login.blank?
      if (u = User.find_by_login(login))
        self.user = u
      end
    end
  end
  
  def <=>(member)
    a, b = roles.sort.first, member.roles.sort.first
    a == b ? (user <=> member.user) : (a <=> b)
  end
  
  def before_destroy
    # remove category based auto assignments for this member
    IssueCategory.update_all "assigned_to_id = NULL", ["project_id = ? AND assigned_to_id = ?", project.id, user.id]
  end
  
  protected
  
  def validate
    errors.add_to_base "Role can't be blank" if roles.empty?
  end
end
