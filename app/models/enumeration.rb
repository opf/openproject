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
  acts_as_list :scope => 'opt = \'#{opt}\''

  before_destroy :check_integrity
  
  validates_presence_of :opt, :name
  validates_uniqueness_of :name, :scope => [:opt]
  validates_length_of :name, :maximum => 30

  # Single table inheritance would be an option
  OPTIONS = {
    "IPRI" => {:label => :enumeration_issue_priorities, :model => Issue, :foreign_key => :priority_id},
    "DCAT" => {:label => :enumeration_doc_categories, :model => Document, :foreign_key => :category_id},
    "ACTI" => {:label => :enumeration_activities, :model => TimeEntry, :foreign_key => :activity_id}
  }.freeze
  
  def self.get_values(option)
    find(:all, :conditions => {:opt => option}, :order => 'position')
  end
  
  def self.default(option)  
    find(:first, :conditions => {:opt => option, :is_default => true}, :order => 'position')
  end

  def option_name
    OPTIONS[self.opt][:label]
  end

  def before_save
    Enumeration.update_all("is_default = #{connection.quoted_false}", {:opt => opt}) if is_default?
  end
  
  def objects_count
    OPTIONS[self.opt][:model].count(:conditions => "#{OPTIONS[self.opt][:foreign_key]} = #{id}")
  end
  
  def in_use?
    self.objects_count != 0
  end
  
  alias :destroy_without_reassign :destroy
  
  # Destroy the enumeration
  # If a enumeration is specified, objects are reassigned
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(Enumeration)
      OPTIONS[self.opt][:model].update_all("#{OPTIONS[self.opt][:foreign_key]} = #{reassign_to.id}", "#{OPTIONS[self.opt][:foreign_key]} = #{id}")
    end
    destroy_without_reassign
  end
  
  def <=>(enumeration)
    position <=> enumeration.position
  end
  
  def to_s; name end
  
private
  def check_integrity
    raise "Can't delete enumeration" if self.in_use?
  end
end
