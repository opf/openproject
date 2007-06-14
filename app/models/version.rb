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
  has_many :attachments, :as => :container, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_format_of :effective_date, :with => /^\d{4}-\d{2}-\d{2}$/, :message => :activerecord_error_not_a_date, :allow_nil => true
  
  def start_date
    effective_date
  end
  
  def due_date
    effective_date
  end
  
  def completed?
    effective_date && effective_date <= Date.today
  end
  
  def wiki_page
    if project.wiki && !wiki_page_title.blank?
      @wiki_page ||= project.wiki.find_page(wiki_page_title)
    end
    @wiki_page
  end
  
  # Versions are sorted by effective_date 
  # Those with no effective_date are at the end, sorted by name
  def <=>(version)
    if self.effective_date
      version.effective_date ? (self.effective_date <=> version.effective_date) : -1
    else
      version.effective_date ? 1 : (self.name <=> version.name)
    end
  end
  
private
  def check_integrity
    raise "Can't delete version" if self.fixed_issues.find(:first)
  end
end
