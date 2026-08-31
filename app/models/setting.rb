# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
  class NotWritableError < StandardError; end

  extend Accessors
  extend Aliases
  extend MailSettings

  PASSWORD_MAX_LENGTH = 128

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
  validates :value,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: PASSWORD_MAX_LENGTH,
              if: ->(setting) { setting.name == "password_min_length" }
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
      raise NotWritableError, "#{name} is not writable but can be set through env vars or configuration.yml file."
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

  # Returns the value of the setting named name
  # The value will be retrieved from that order:
  # 1. An overwritten definition (e.g., when provided as ENV var)
  # 2. The cached database value
  # 3. The setting definition default
  def self.cached_or_default(name)
    name = name.to_s
    raise "There's no setting named #{name}" unless exists?(name)

    definition = Settings::Definition[name]

    # Non-writable settings always use definition value (e.g., from ENV vars)
    return deserialize(name, definition.value) unless definition.writable?

    resolve_writable_value(name, definition)
  end

  # Resolves the value for a writable setting by checking (in order):
  # 1. Cache (RequestStore, or Rails.cache populated from DB)
  # 2. Persisted default value if setting has persist_on_first_read?
  # 3. Definition default
  def self.resolve_writable_value(name, definition)
    settings_cache = cached_settings
    if settings_cache.key?(name)
      deserialize(name, settings_cache[name])
    elsif definition.persist_on_first_read?
      persist_default_value(name)
    else
      deserialize(name, definition.value)
    end
  end

  # Persists the setting's default value to the database on first read.
  # Uses advisory locking to prevent race conditions when multiple processes
  # attempt to initialize the same setting concurrently.
  #
  # After persisting, clears the cache so subsequent calls to cached_settings
  # will include the newly created setting.
  def self.persist_default_value(name)
    definition = Settings::Definition[name]
    return definition.value unless settings_table_exists_yet?

    OpenProject::Mutex.with_advisory_lock(Setting, "persist_default_#{name}") do
      # Once we acquired the lock, check again whether the setting was not created by now.
      setting = find_by(name:)
      return setting.value if setting

      generated_value = definition.default
      create!(name:, value: formatted_value_for(generated_value, definition))

      # Clear cache so the next setting call populates it with this value
      clear_cache
      generated_value
    end
  end

  def self.formatted_value_for(value, definition)
    return value.to_yaml if definition.serialized?

    value.to_s
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

    if definition.nil?
      nil
    elsif definition.serialized? && value.is_a?(String)
      deserialize_hash(value)
    elsif value != "" && !value.nil?
      read_formatted_setting(value, definition.format)
    elsif definition.format == :string
      value
    end
  end

  def self.deserialize_hash(value)
    YAML::safe_load(value, permitted_classes: [Symbol, ActiveSupport::HashWithIndifferentAccess, Date, Time, URI::Generic])
      .tap { |maybe_hash| normalize_hash!(maybe_hash) if maybe_hash.is_a?(Hash) }
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
