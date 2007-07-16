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
  has_many :custom_values, :dependent => :delete_all
  serialize :possible_values
  
  FIELD_FORMATS = { "string" => { :name => :label_string, :order => 1 },
                    "text" => { :name => :label_text, :order => 2 },
                    "int" => { :name => :label_integer, :order => 3 },
                    "list" => { :name => :label_list, :order => 4 },
			        "date" => { :name => :label_date, :order => 5 },
			        "bool" => { :name => :label_boolean, :order => 6 }
  }.freeze

  validates_presence_of :name, :field_format
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i
  validates_inclusion_of :field_format, :in => FIELD_FORMATS.keys

  def initialize(attributes = nil)
    super
    self.possible_values ||= []
  end
  
  def before_validation
    # remove empty values
    self.possible_values = self.possible_values.collect{|v| v unless v.empty?}.compact
  end
  
  def validate
    if self.field_format == "list"
      errors.add(:possible_values, :activerecord_error_blank) if self.possible_values.nil? || self.possible_values.empty?
      errors.add(:possible_values, :activerecord_error_invalid) unless self.possible_values.is_a? Array
    end
  end

  # to move in project_custom_field
  def self.for_all
    find(:all, :conditions => ["is_for_all=?", true])
  end
  
  def type_name
    nil
  end
end
