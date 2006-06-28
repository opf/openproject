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

class Version < ActiveRecord::Base
  before_destroy :check_integrity  
	belongs_to :project
	has_many :fixed_issues, :class_name => 'Issue', :foreign_key => 'fixed_version_id'
  has_many :attachments, :as => :container, :dependent => true
	
	validates_presence_of :name, :descr
  
private
  def check_integrity
    raise "Can't delete version" if self.fixed_issues.find(:first)
  end
end
