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
  acts_as_list :scope => 'type = \'#{type}\''

  before_destroy :check_integrity
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:type]
  validates_length_of :name, :maximum => 30
  
  # Backwards compatiblity named_scopes.
  # Can be removed post-0.9
  named_scope :priorities, :conditions => { :type => "IssuePriority" }, :order => 'position' do
    ActiveSupport::Deprecation.warn("Enumeration#priorities is deprecated, use the IssuePriority class. (#{Redmine::Info.issue(3007)})")
    def default
      find(:first, :conditions => { :is_default => true })
    end
  end

  named_scope :document_categories, :conditions => { :type => "DocumentCategory" }, :order => 'position' do
    ActiveSupport::Deprecation.warn("Enumeration#document_categories is deprecated, use the DocumentCategories class. (#{Redmine::Info.issue(3007)})")
    def default
      find(:first, :conditions => { :is_default => true })
    end
  end

  named_scope :activities, :conditions => { :type => "TimeEntryActivity" }, :order => 'position' do
    ActiveSupport::Deprecation.warn("Enumeration#activities is deprecated, use the TimeEntryActivity class. (#{Redmine::Info.issue(3007)})")
    def default
      find(:first, :conditions => { :is_default => true })
    end
  end
  
  named_scope :values, lambda {|type| { :conditions => { :type => type }, :order => 'position' } } do
    def default
      find(:first, :conditions => { :is_default => true })
    end
  end

  named_scope :all, :order => 'position'

  def self.default
    # Creates a fake default scope so Enumeration.default will check
    # it's type.  STI subclasses will automatically add their own
    # types to the finder.
    if self.descends_from_active_record?
      find(:first, :conditions => { :is_default => true, :type => 'Enumeration' })
    else
      # STI classes are
      find(:first, :conditions => { :is_default => true })
    end
  end
  
  # Overloaded on concrete classes
  def option_name
    nil
  end

  # Backwards compatiblity.  Can be removed post-0.9
  def opt
    ActiveSupport::Deprecation.warn("Enumeration#opt is deprecated, use the STI classes now. (#{Redmine::Info.issue(3007)})")
    return OptName
  end

  def before_save
    if is_default? && is_default_changed?
      Enumeration.update_all("is_default = #{connection.quoted_false}", {:type => type})
    end
  end
  
  # Overloaded on concrete classes
  def objects_count
    0
  end
  
  def in_use?
    self.objects_count != 0
  end
  
  alias :destroy_without_reassign :destroy
  
  # Destroy the enumeration
  # If a enumeration is specified, objects are reassigned
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(Enumeration)
      self.transfer_relations(reassign_to)
    end
    destroy_without_reassign
  end
  
  def <=>(enumeration)
    position <=> enumeration.position
  end
  
  def to_s; name end

  # Returns the Subclasses of Enumeration.  Each Subclass needs to be
  # required in development mode.
  #
  # Note: subclasses is protected in ActiveRecord
  def self.get_subclasses
    @@subclasses[Enumeration]
  end
  
private
  def check_integrity
    raise "Can't delete enumeration" if self.in_use?
  end

end

# Force load the subclasses in development mode
require_dependency 'time_entry_activity'
require_dependency 'document_category'
require_dependency 'issue_priority'
