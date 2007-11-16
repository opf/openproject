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

  DATE_FORMATS = [
	'%Y-%m-%d',
	'%d/%m/%Y',
	'%d.%m.%Y',
	'%d-%m-%Y',
	'%m/%d/%Y',
	'%d %b %Y',
	'%d %B %Y',
	'%b %d, %Y',
	'%B %d, %Y'
    ]
    
  TIME_FORMATS = [
    '%H:%M',
    '%I:%M %p'
    ]
  
  cattr_accessor :available_settings
  @@available_settings = YAML::load(File.open("#{RAILS_ROOT}/config/settings.yml"))
  Redmine::Plugin.registered_plugins.each do |id, plugin|
    next unless plugin.settings
    @@available_settings["plugin_#{id}"] = {'default' => plugin.settings[:default], 'serialized' => true}    
  end
  
  validates_uniqueness_of :name
  validates_inclusion_of :name, :in => @@available_settings.keys
  validates_numericality_of :value, :only_integer => true, :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'int' }  

  # Hash used to cache setting values
  @cached_settings = {}
  @cached_cleared_on = Time.now
  
  def value
    v = read_attribute(:value)
    # Unserialize serialized settings
    v = YAML::load(v) if @@available_settings[name]['serialized'] && v.is_a?(String)
    v
  end
  
  def value=(v)
    v = v.to_yaml if v && @@available_settings[name]['serialized']
    write_attribute(:value, v)
  end
  
  # Returns the value of the setting named name
  def self.[](name)
    v = @cached_settings[name]
    v ? v : (@cached_settings[name] = find_or_default(name).value)
  end
  
  def self.[]=(name, v)
    setting = find_or_default(name)
    setting.value = (v ? v : "")
    @cached_settings[name] = nil
    setting.save
    setting.value
  end
  
  # Defines getter and setter for each setting
  # Then setting values can be read using: Setting.some_setting_name
  # or set using Setting.some_setting_name = "some value"
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
  
  # Checks if settings have changed since the values were read
  # and clears the cache hash if it's the case
  # Called once per request
  def self.check_cache
    settings_updated_on = Setting.maximum(:updated_on)
    if settings_updated_on && @cached_cleared_on <= settings_updated_on
      @cached_settings.clear
      @cached_cleared_on = Time.now
      logger.info "Settings cache cleared." if logger
    end
  end
  
private
  # Returns the Setting instance for the setting named name
  # (record found in database or new record with default value)
  def self.find_or_default(name)
    name = name.to_s
    raise "There's no setting named #{name}" unless @@available_settings.has_key?(name)    
    setting = find_by_name(name)
    setting ||= new(:name => name, :value => @@available_settings[name]['default']) if @@available_settings.has_key? name
  end
end
