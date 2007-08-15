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

class Wiki < ActiveRecord::Base
  belongs_to :project
  has_many :pages, :class_name => 'WikiPage', :dependent => :destroy
  
  validates_presence_of :start_page
  validates_format_of :start_page, :with => /^[^,\.\/\?\;\|\:]*$/
  
  # find the page with the given title
  # if page doesn't exist, return a new page
  def find_or_new_page(title)
    title = Wiki.titleize(title || start_page)
    find_page(title) || WikiPage.new(:wiki => self, :title => title)  
  end
  
  # find the page with the given title
  def find_page(title)
    title = start_page if title.blank?
    pages.find_by_title(Wiki.titleize(title))
  end
  
  # turn a string into a valid page title
  def self.titleize(title)
    # replace spaces with _ and remove unwanted caracters
    title = title.gsub(/\s+/, '_').delete(',./?;|:') if title
    # upcase the first letter
    title = (title.length > 1 ? title.first.upcase + title[1..-1] : title.upcase) if title
    title
  end  
end
