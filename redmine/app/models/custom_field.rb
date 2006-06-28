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

class CustomField < ActiveRecord::Base

	has_and_belongs_to_many :projects	
	has_many :custom_values, :dependent => true
	has_many :issues, :through => :issue_custom_values

	validates_presence_of :name, :typ	
	validates_uniqueness_of :name

	TYPES = [
			[ "Integer", 0 ],
			[ "String", 1 ],
			[ "Date", 2 ],
			[ "Boolean", 3 ],
			[ "List", 4 ]
	].freeze
	
	def self.for_all
		find(:all, :conditions => ["is_for_all=?", true])
	end
end
