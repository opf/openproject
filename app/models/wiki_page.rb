# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class WikiPage < ActiveRecord::Base
  belongs_to :wiki
  has_one :content, :class_name => 'WikiContent', :foreign_key => 'page_id', :dependent => :destroy
  
  validates_presence_of :title
  validates_format_of :title, :with => /^[^,\s]*$/
  validates_uniqueness_of :title, :scope => :wiki_id, :case_sensitive => false
  validates_associated :content
  
  def before_save
    self.title = Wiki.titleize(title)
  end
  
  def pretty_title
    WikiPage.pretty_title(title)
  end
  
  def content_for_version(version=nil)
    result = content.versions.find_by_version(version.to_i) if version
    result ||= content
    result
  end
  
  def self.pretty_title(str)
    (str && str.is_a?(String)) ? str.tr('_', ' ') : str
  end
end
