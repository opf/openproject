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
    
  ENCODINGS = %w(US-ASCII
                  windows-1250
                  windows-1251
                  windows-1252
                  windows-1253
                  windows-1254
                  windows-1255
                  windows-1256
                  windows-1257
                  windows-1258
                  windows-31j
                  ISO-2022-JP
                  ISO-2022-KR
                  ISO-8859-1
                  ISO-8859-2
                  ISO-8859-3
                  ISO-8859-4
                  ISO-8859-5
                  ISO-8859-6
                  ISO-8859-7
                  ISO-8859-8
                  ISO-8859-9
                  ISO-8859-13
                  ISO-8859-15
                  KOI8-R
                  UTF-8
                  UTF-16
                  UTF-16BE
                  UTF-16LE
                  EUC-JP
                  Shift_JIS
                  CP932
                  GB18030
                  GBK
                  ISCII91
                  EUC-KR
                  Big5
                  Big5-HKSCS
                  TIS-620)
  
  cattr_accessor :available_settings
  @@available_settings = YAML::load(File.open("#{RAILS_ROOT}/config/settings.yml"))
  Redmine::Plugin.all.each do |plugin|
    next unless plugin.settings
    @@available_settings["plugin_#{plugin.id}"] = {'default' => plugin.settings[:default], 'serialized' => true}    
  end
  
  validates_uniqueness_of :name
  validates_inclusion_of :name, :in => @@available_settings.keys
  validates_numericality_of :value, :only_integer => true, :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'int' }  
  
  def value
    v = read_attribute(:value)
    # Unserialize serialized settings
    v = YAML::load(v) if @@available_settings[name]['serialized'] && v.is_a?(String)
    v = v.to_sym if @@available_settings[name]['format'] == 'symbol' && !v.blank?
    v
  end
  
  def value=(v)
    v = v.to_yaml if v && @@available_settings[name] && @@available_settings[name]['serialized']
    write_attribute(:value, v.to_s)
  end
  
  # Returns the value of the setting named name
  def self.[](name)
    Marshal.load(Rails.cache.fetch("chiliproject/setting/#{name}") {Marshal.dump(find_or_default(name).value)}).freeze
  end
  
  def self.[]=(name, v)
    setting = find_or_default(name)
    setting.value = (v ? v : "")
    Rails.cache.delete "chiliproject/setting/#{name}"
    setting.save
    setting.value.freeze
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
  
  # Helper that returns an array based on per_page_options setting
  def self.per_page_options_array
    per_page_options.split(%r{[\s,]}).collect(&:to_i).select {|n| n > 0}.sort
  end
  
  def self.openid?
    Object.const_defined?(:OpenID) && self[:openid].to_i > 0
  end
  
  # Checks if settings have changed since the values were read
  # and clears the cache hash if it's the case
  # Called once per request
  def self.check_cache
    settings_updated_on = Setting.maximum(:updated_on)
    cache_cleared_on = Rails.cache.read('chiliproject/setting-cleared_on')
    cache_cleared_on = cache_cleared_on ? Marshal.load(cache_cleared_on) : Time.now
    if settings_updated_on && cache_cleared_on <= settings_updated_on
      Rails.cache.delete_matched( /^chiliproject\/setting\/.+$/ )
      Rails.cache.write('chiliproject/setting-cleared_on', Marshal.dump(Time.now))
      logger.info 'Settings cache cleared.' if logger
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
