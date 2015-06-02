#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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

  def self.create_setting(name, value = nil)
    @@available_settings[name] = value
  end

  def self.create_setting_accessors(name)
    # Defines getter and setter for each setting
    # Then setting values can be read using: Setting.some_setting_name
    # or set using Setting.some_setting_name = "some value"
    src = <<-END_SRC
      def self.#{name}
        # when running too early, there is no settings table. do nothing
        self[:#{name}] if settings_table_exists_yet?
      end

      def self.#{name}?
        # when running too early, there is no settings table. do nothing
        self[:#{name}].to_i > 0 if settings_table_exists_yet?
      end

      def self.#{name}=(value)
        if settings_table_exists_yet?
          self[:#{name}] = value
        else
          logger.warn "Trying to save a setting named '#{name}' while there is no 'setting' table yet. This setting will not be saved!"
          nil # when runnung too early, there is no settings table. do nothing
        end
      end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  @@available_settings = YAML::load(File.open(Rails.root.join('config/settings.yml')))

  # Defines getter and setter for each setting
  # Then setting values can be read using: Setting.some_setting_name
  # or set using Setting.some_setting_name = "some value"
  @@available_settings.each do |name, _params|
    create_setting_accessors(name)
  end

  validates_uniqueness_of :name
  validates_inclusion_of :name, in: lambda { |_setting| @@available_settings.keys } # lambda, because @available_settings changes at runtime
  validates_numericality_of :value, only_integer: true, if: Proc.new { |setting| @@available_settings[setting.name]['format'] == 'int' }

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
    Marshal.load(Rails.cache.fetch(cache_key(name)) { Marshal.dump(find_or_default(name).value) })
  end

  def self.[]=(name, v)
    setting = find_or_default(name)
    # remember the old setting and mark it as read-only
    old_setting = setting.dup.freeze
    setting.value = (v ? v : '')
    Rails.cache.delete(cache_key(name))
    if setting.save
      # fire callbacks for name and pass as much information as possible
      fire_callbacks(name, setting, old_setting)
      setting.value
    else
      old_setting.value
    end
  end

  # Check whether a setting was defined
  def self.exists?(name)
    @@available_settings.has_key?(name)
  end

  # this should be fixed with globalize plugin
  [:emails_header, :emails_footer].each do |mail|
    src = <<-END_SRC
    def self.localized_#{mail}
      I18n.fallbacks[I18n.locale].each do |lang|
        text = self[:#{mail}][lang.to_s]
        return text unless text.blank?
      end
      ''
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  # Helper that returns an array based on per_page_options setting
  def self.per_page_options_array
    per_page_options.split(%r{[\s,]}).map(&:to_i).select { |n| n > 0 }.sort
  end

  private

  # Returns the Setting instance for the setting named name
  # (record found in database or new record with default value)
  def self.find_or_default(name)
    name = name.to_s
    raise "There's no setting named #{name}" unless exists? name
    find_by_name(name) or new do |s|
      s.name  = name
      s.value = @@available_settings[name]['default']
    end
  end

  def self.cache_key(name)
    RequestStore.store[:settings_updated_on] ||= Setting.maximum(:updated_on)
    most_recent_settings_change = (RequestStore.store[:settings_updated_on] || Time.now.utc).to_i
    base_cache_key(name, most_recent_settings_change)
  end

  def self.base_cache_key(name, timestamp)
    "/openproject/settings/#{timestamp}/#{name}"
  end

  def self.settings_table_exists_yet?
    # Check whether the settings table already exists. This makes plugins
    # patching core classes not break things when settings are accessed.
    # I'm not sure this is a good idea, but that's the way it is right now,
    # and caching this improves performance significantly for actions
    # accessing settings a lot.
    @settings_table_exists_yet ||= connection.table_exists?(table_name)
  end

  require_dependency 'setting/callbacks'
  extend Callbacks
end
