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

class Project < ActiveRecord::Base
	has_many :versions, :dependent => true, :order => "versions.date DESC"
	has_many :members, :dependent => true
	has_many :issues, :dependent => true, :order => "issues.created_on DESC", :include => :status
	has_many :documents, :dependent => true
	has_many :news, :dependent => true, :order => "news.created_on DESC", :include => :author
	has_many :issue_categories, :dependent => true
	has_and_belongs_to_many :custom_fields
	
	validates_presence_of :name, :descr
	
	# returns 5 last created projects
	def self.latest
		find(:all, :limit => 5, :order => "created_on DESC")	
	end	
	
	# Returns current version of the project
	def current_version
		versions.find(:first, :conditions => [ "date <= ?", Date.today ], :order => "date DESC, id DESC")
	end
	
	# Returns an array of all custom fields enabled for project issues
	# (explictly associated custom fields and custom fields enabled for all projects)
	def custom_fields_for_issues
		(CustomField.for_all + custom_fields).uniq
	end
end
