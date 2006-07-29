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

class Enumeration < ActiveRecord::Base
  before_destroy :check_integrity
  
	validates_presence_of :opt, :name
	validates_uniqueness_of :name, :scope => [:opt]
	
	OPTIONS = {
	  "IPRI" => :enumeration_issue_priorities,
      "DCAT" => :enumeration_doc_categories
	}.freeze
	
	def self.get_values(option)
		find(:all, :conditions => ['opt=?', option])
	end
  
private
  def check_integrity
    case self.opt
    when "IPRI"
      raise "Can't delete enumeration" if Issue.find(:first, :conditions => ["priority_id=?", self.id])
    when "DCAT"
      raise "Can't delete enumeration" if Document.find(:first, :conditions => ["category_id=?", self.id])
    end
  end
end
