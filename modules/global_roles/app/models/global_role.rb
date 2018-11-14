#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class GlobalRole < Role
  has_many :principal_roles, foreign_key: :role_id, dependent: :destroy
  has_many :principals, through: :principal_roles, dependent: :destroy

  def initialize(*args)
    super
    self.assignable = false
  end

  def setable_permissions
    Redmine::AccessControl.global_permissions
  end

  def self.setable_permissions
    Redmine::AccessControl.global_permissions
  end

  def to_s
    name
  end

  def assignable=(value)
    fail ArgumentError if value == true
    super
  end

  def assignable_to?(_user)
    true
  end
end
