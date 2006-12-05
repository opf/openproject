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

class UserPreference < ActiveRecord::Base
  belongs_to :user
  serialize :others, Hash
  
  attr_protected :others
  
  def initialize(attributes = nil)
    super
    self.others ||= {}
  end
  
  def [](attr_name)
    if attribute_present? attr_name
      super
    else
      others[attr_name]
    end
  end
  
  def []=(attr_name, value)
    if attribute_present? attr_name
      super
    else
      others.store attr_name, value
    end
  end
end
