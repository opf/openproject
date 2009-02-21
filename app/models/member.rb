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

class Member < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :project

  validates_presence_of :role, :user, :project
  validates_uniqueness_of :user_id, :scope => :project_id

  def validate
    errors.add :role_id, :invalid if role && !role.member?
  end
  
  def name
    self.user.name
  end
  
  def <=>(member)
    role == member.role ? (user <=> member.user) : (role <=> member.role)
  end
  
  def before_destroy
    # remove category based auto assignments for this member
    IssueCategory.update_all "assigned_to_id = NULL", ["project_id = ? AND assigned_to_id = ?", project.id, user.id]
  end
end
