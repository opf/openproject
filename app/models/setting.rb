#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Setting < ApplicationRecord
  extend Aliases
  extend MailSettings

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
                 TIS-620).freeze

  class << self
    def create_setting(name, value = {})
      ::Settings::Definition.add(name, **value.symbolize_keys)
    end

    def create_setting_accessors(name)
      return if [:installation_uuid].include?(name.to_sym)

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
          return unless settings_table_exists_yet?
          definition = Settings::Definition[:#{name}]

          if definition.format != :boolean
            ActiveSupport::Deprecation.warn "Calling #{self}.#{name}? is deprecated since it is not a boolean", caller
          end

          value = self[:#{name}]
          ActiveRecord::Type::Boolean.new.cast(value) || false
        end

        def self.#{name}=(value)
          if settings_table_exists_yet?
            self[:#{name}] = value
          else
            logger.warn "Trying to save a setting named '#{name}' while there is no 'setting' table yet. This setting will not be saved!"
            nil # when running too early, there is no settings table. do nothing
          end
        end

        def self.#{name}_writable?
          Settings::Definition[:#{name}].writable?
        end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    def method_missing(method, *, &)
      if exists?(accessor_base_name(method))
        create_setting_accessors(accessor_base_name(method))

        send(method, *)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      exists?(accessor_base_name(method_name)) || super
    end

    private

    def accessor_base_name(name)
      name.to_s.sub(/(_writable\?)|(\?)|=\z/, '')
    end
  end

  validates :name,
            uniqueness: true,
            inclusion: {
              in: ->(*) { Settings::Definition.all.keys.map(&:to_s) } # @available_settings change at runtime
            }
  validates :value,
            numericality: {
              only_integer: true,
              if: ->(setting) { setting.non_null_integer_format? }
            }
  validates :value,
            numericality: {
              only_integer: true,
              allow_nil: true,
              if: ->(setting) { setting.nullable_integer_format? }
            }

  def nullable_integer_format?
    format == :integer && definition.default.nil?
  end

  def non_null_integer_format?
    format == :integer && !definition.default.nil?
  end

  def value
    self.class.deserialize(name, read_attribute(:value))
  end

  def value=(val)
    set_value! val
  end

  def set_value!(val, force: false)
    unless force || definition.writable?
      raise NoMethodError, "#{name} is not writable but can be set through env vars or configuration.yml file."
    end

    self[:value] = formatted_value(val)
  end

  def formatted_value(value)
    return value if value.blank?

    if definition.serialized?
      return value.to_yaml
    end

    value.to_s
  end

  # Returns the value of the setting named name
  def self.[](name)
    cached_or_default(name)
  end

  def self.[]=(name, value)
    old_value = cached_or_default(name)
    new_setting = find_or_initialize_by(name:)
    new_setting.value = value

    # Keep the current cache key,
    # since updated_at will change after .save
    old_cache_key = cache_key

    if new_setting.save
      new_value = new_setting.value

      # Delete the cache
      clear_cache(old_cache_key)

      new_value
    else
      old_value
    end
  end

  # Check whether a setting was defined
  def self.exists?(name)
    Settings::Definition[name].present?
  end

  def self.installation_uuid
    if settings_table_exists_yet?
      # we avoid the default getters and setters since the cache messes things up
      setting = find_or_initialize_by(name: "installation_uuid")
      if setting.value.blank?
        setting.value = generate_installation_uuid
        setting.save!
      end
      setting.value
    else
      "unknown"
    end
  end

  def self.generate_installation_uuid
    if Rails.env.test?
      "test"
    else
      SecureRandom.uuid
    end
  end

  %i[emails_header emails_footer].each do |mail|
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
    per_page_options
      .split(%r{[\s,]})
      .map(&:to_i)
      .select(&:positive?)
      .sort
  end

  def self.clear_cache(key = cache_key)
    Rails.cache.delete(key)
    RequestStore.delete :cached_settings
    RequestStore.delete :settings_updated_at
  end

  # Returns the Setting instance for the setting named name
  # The setting can come from either
  # * The database
  # * The cached database value
  # * The setting definition
  #
  # In case the definition is overwritten, e.g. via an ENV var,
  # the definition value will always be used.
  def self.cached_or_default(name)
    name = name.to_s
    raise "There's no setting named #{name}" unless exists? name

    definition = Settings::Definition[name]

    value = if definition.writable?
              cached_settings.fetch(name) { definition.value }
            else
              definition.value
            end

    deserialize(name, value)
  end

  # Returns the settings from two levels of cache
  # 1. The current rack request using RequestStore
  # 2. Rails.cache serialized settings hash
  #
  # Unless one cache hits, it plucks from the database
  # Returns a hash of setting => (possibly serialized) value
  def self.cached_settings
    RequestStore.fetch(:cached_settings) do
      Rails.cache.fetch(cache_key) do
        Setting.pluck(:name, :value).to_h
      end
    end
  end

  def self.cache_key
    most_recent_settings_change = (settings_updated_at || Time.now.utc).to_i

    "/openproject/settings/all/#{most_recent_settings_change}"
  end

  def self.settings_updated_at
    RequestStore.store[:settings_updated_at] ||= has_updated_at_column? && Setting.maximum(:updated_at)
  end

  def self.has_updated_at_column?
    return @has_updated_at_column unless @has_updated_at_column.nil?

    @has_updated_at_column = Setting.column_names.map(&:to_sym).include?(:updated_at)
  end

  def self.settings_table_exists_yet?
    # Check whether the settings table already exists. This makes plugins
    # patching core classes not break things when settings are accessed.
    # I'm not sure this is a good idea, but that's the way it is right now,
    # and caching this improves performance significantly for actions
    # accessing settings a lot.
    @settings_table_exists_yet ||= connection.data_source_exists?(table_name)
  end

  # Deserialize a serialized settings value
  def self.deserialize(name, value)
    definition = Settings::Definition[name]

    if definition.serialized? && value.is_a?(String)
      YAML::safe_load(value, permitted_classes: [Symbol, ActiveSupport::HashWithIndifferentAccess, Date, Time, URI::Generic])
        .tap { |maybe_hash| normalize_hash!(maybe_hash) if maybe_hash.is_a?(Hash) }
    elsif value != ''.freeze && !value.nil?
      read_formatted_setting(value, definition.format)
    else
      definition.format == :string ? value : nil
    end
  end

  def self.normalize_hash!(hash)
    hash.deep_stringify_keys!
    hash.deep_transform_values! { |v| v.is_a?(URI::Generic) ? v.to_s : v }
  end

  def self.read_formatted_setting(value, format)
    case format
    when :boolean
      ActiveRecord::Type::Boolean.new.cast(value)
    when :symbol
      value.to_sym
    when :integer
      value.to_i
    when :date
      Date.parse value
    when :datetime
      DateTime.parse value
    else
      value
    end
  end

  protected

  def definition
    @definition ||= Settings::Definition[name]
  end

  delegate :format,
           to: :definition
end
