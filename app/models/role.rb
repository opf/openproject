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
  before_destroy :check_integrity  
  has_and_belongs_to_many :permissions
  has_many :workflows, :dependent => :delete_all
  has_many :members
  acts_as_list

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i

private
  def check_integrity
    raise "Can't delete role" if Member.find(:first, :conditions =>["role_id=?", self.id])
  end
end
