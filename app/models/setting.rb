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

class Setting < ActiveRecord::Base

  cattr_accessor :available_settings
  @@available_settings = YAML::load(File.open("#{RAILS_ROOT}/config/settings.yml"))

  validates_uniqueness_of :name
  validates_inclusion_of :name, :in => @@available_settings.keys
  validates_numericality_of :value, :only_integer => true, :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'int' }  
  
  def self.get(name)
    name = name.to_s
    setting = find_by_name(name)
    setting ||= new(:name => name, :value => @@available_settings[name]['default']) if @@available_settings.has_key? name
    setting
  end
  
  def self.[](name)
    get(name).value
  end
  
  def self.[]=(name, value)
    setting = get(name)
    setting.value = (value ? value.to_s : "")
    setting.save
    setting.value
  end
  
  @@available_settings.each do |name, params|
    src = <<-END_SRC
    def self.#{name}
      self[:#{name}]
    end

    def self.#{name}?
      self[:#{name}].to_i > 0
    end

    def self.#{name}=(value)
      self[:#{name}] = value
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end
end
