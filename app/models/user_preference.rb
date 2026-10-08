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

class UserPreference < ApplicationRecord
  belongs_to :user
  delegate :notification_settings, to: :user
  serialize :settings, coder: ::Serializers::IndifferentHashSerializer

  validates :user,
            presence: true

  WORKDAYS_FROM_MONDAY_TO_FRIDAY = [1, 2, 3, 4, 5].freeze

  COLOR_MODES = %i[light dark].freeze
  THEMES = (COLOR_MODES + %i[sync_with_os]).freeze

  ##
  # Retrieve keys from settings, and allow accessing
  # as boolean with ? suffix
  def method_missing(method_name, *args)
    key = method_name.to_s
    return super unless supported_settings_method?(key)

    action = key[-1]

    case action
    when "?"
      to_boolean send(key[..-2])
    when "="
      settings[key[..-2]] = args.first
    else
      settings[key]
    end
  end

  ##
  # We respond to all methods as we retrieve
  # the key from settings
  def respond_to_missing?(method_name, include_private = false)
    supported_settings_method?(method_name) || super
  end

  def [](attr_name)
    if attribute?(attr_name)
      super
    else
      send attr_name
    end
  end

  def []=(attr_name, value)
    if attribute?(attr_name)
      super
    else
      send :"#{attr_name}=", value
    end
  end

  def comments_sorting
    settings.fetch(:comments_sorting, OpenProject::Configuration.default_comment_sort_order)
  end

  def comments_in_reverse_order?
    comments_sorting == "desc"
  end

  def disable_keyboard_shortcuts?
    settings.fetch(:disable_keyboard_shortcuts) { Setting.disable_keyboard_shortcuts? }
  end

  def disable_keyboard_shortcuts=(value)
    settings[:disable_keyboard_shortcuts] = to_boolean(value)
  end

  def diff_type
    settings.fetch(:diff_type, "inline")
  end

  def auto_hide_popups=(value)
    settings[:auto_hide_popups] = to_boolean(value)
  end

  def auto_hide_popups?
    settings.fetch(:auto_hide_popups) { Setting.default_auto_hide_popups? }
  end

  def warn_on_leaving_unsaved?
    settings.fetch(:warn_on_leaving_unsaved, true)
  end

  def warn_on_leaving_unsaved=(value)
    settings[:warn_on_leaving_unsaved] = to_boolean(value)
  end

  # Provide an alias to form builders
  alias :comments_in_reverse_order :comments_in_reverse_order?
  alias :warn_on_leaving_unsaved :warn_on_leaving_unsaved?
  alias :auto_hide_popups :auto_hide_popups?
  alias :disable_keyboard_shortcuts :disable_keyboard_shortcuts?

  def comments_in_reverse_order=(value)
    settings[:comments_sorting] = to_boolean(value) ? "desc" : "asc"
  end

  def theme
    super.presence || Setting.user_default_theme
  end

  def increase_theme_contrast=(value)
    settings[:increase_theme_contrast] = to_boolean(value)
  end

  def force_light_theme_contrast=(value)
    settings[:force_light_theme_contrast] = to_boolean(value)
  end

  def force_dark_theme_contrast=(value)
    settings[:force_dark_theme_contrast] = to_boolean(value)
  end

  COLOR_MODES.each do |color_mode|
    define_method("#{color_mode}_color_mode?") { theme.split("_", 2)[0] == color_mode.to_s }
  end

  THEMES.each do |theme_name|
    define_method("#{theme_name}_theme?") { theme == theme_name.to_s }
  end

  def light_high_contrast_theme?
    light_theme? && increase_theme_contrast?
  end

  def dark_high_contrast_theme?
    dark_theme? && increase_theme_contrast?
  end

  def time_zone
    super.presence || Setting.user_default_timezone.presence || "Etc/UTC"
  end

  def time_zone?
    settings["time_zone"].present?
  end

  def daily_reminders
    super.presence || { enabled: true, times: ["08:00:00+00:00"] }.with_indifferent_access
  end

  def daily_reminders=(value)
    hash = value.to_h.with_indifferent_access
    self.settings = settings.merge(
      "daily_reminders" => {
        "enabled" => ActiveRecord::Type::Boolean.new.cast(hash[:enabled]),
        "times" => Array(hash[:times]).compact_blank
      }
    )
  end

  def workdays
    super || WORKDAYS_FROM_MONDAY_TO_FRIDAY
  end

  def workdays=(value)
    self.settings = settings.merge("workdays" => Array(value).map(&:to_i))
  end

  def immediate_reminders
    super.presence || { mentioned: true, personal_reminder: true }.with_indifferent_access
  end

  def immediate_reminders=(value)
    self.settings = settings.merge(
      "immediate_reminders" => value.to_h.with_indifferent_access.transform_values { |v| ActiveRecord::Type::Boolean.new.cast(v) }
    )
  end

  def mentioned
    immediate_reminders[:mentioned]
  end

  def personal_reminder
    immediate_reminders[:personal_reminder]
  end

  def pause_reminders
    super.presence || { enabled: false }.with_indifferent_access
  end

  def pause_reminders=(value)
    hash = value.to_h.with_indifferent_access
    self.settings = settings.merge("pause_reminders" => pause_reminders_hash(hash))
  end

  def dismissed_banner?(feature)
    dismissed_enterprise_banners.key?(feature.to_s)
  end

  def dismiss_banner(feature)
    dismissed_enterprise_banners[feature.to_s] = Time.zone.now.utc
  end

  def supported_settings_method?(method_name)
    UserPreferences::Schema.properties.include?(method_name.to_s.gsub(/\?|=\z/, ""))
  end

  private

  def to_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def attribute?(name)
    %i[user user_id].include?(name.to_sym)
  end

  def pause_reminders_hash(hash)
    result = { "enabled" => ActiveRecord::Type::Boolean.new.cast(hash[:enabled]) }
    date_fields = if hash[:date_range].present?
                    parsed_date_range(hash[:date_range])
                  else
                    { "first_day" => hash[:first_day].presence, "last_day" => hash[:last_day].presence }
                  end
    result.merge(date_fields).compact
  end

  def parsed_date_range(date_range)
    return {} if date_range.blank?

    first_day, last_day = date_range.split(" - ", 2)
    { "first_day" => first_day.presence, "last_day" => last_day.presence }
  end
end
