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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class UserPreference < ApplicationRecord
  belongs_to :user
  delegate :notification_settings, to: :user

  WORKDAYS_FROM_MONDAY_TO_FRIDAY = [1, 2, 3, 4, 5].freeze
  ISO_WEEKDAYS = (1..7)
  DEFAULT_DAILY_REMINDERS_TIMES = ["08:00:00+00:00"].freeze
  FULL_HOUR_REMINDER_TIME = /\A([01]\d|2[0-3]):00:00\+00:00\z/

  COLOR_MODES = %i[light dark].freeze
  THEMES = (COLOR_MODES + %i[sync_with_os]).freeze
  COMMENTS_SORTINGS = %w[asc desc].freeze
  DIFF_TYPES = %w[inline sbs].freeze
  MY_WORK_VIEW_MODES = %w[list calendar stack].freeze
  MY_WORK_MODES = %w[day week workweek month].freeze
  AVATAR_TYPES = %w[gravatar image initials].freeze

  validates :user,
            presence: true

  # Time zone and formats are checked only when changed, as the lists of allowed values can
  # change between releases and must not block unrelated saves of existing preferences.
  store_attribute :settings, :time_zone, :string
  validate :time_zone_assignable, if: :time_zone_changed?

  store_attribute :settings, :date_format, :string
  validates :date_format,
            inclusion: { in: ->(*) { Settings::Definition[:date_format].allowed } },
            allow_blank: true,
            if: :date_format_changed?

  store_attribute :settings, :time_format, :string
  validates :time_format,
            inclusion: { in: ->(*) { Settings::Definition[:time_format].allowed } },
            allow_blank: true,
            if: :time_format_changed?

  store_attribute :settings, :avatar_color, :string
  validates :avatar_color, format: { with: /\A#[0-9A-F]{6}\z/ }, allow_blank: true

  store_attribute :settings, :avatar_text, :string
  validates :avatar_text, avatar_text: true, allow_nil: true

  store_attribute :settings, :avatar_type, :string
  validates :avatar_type, inclusion: { in: AVATAR_TYPES }, allow_nil: true

  store_attribute :settings, :theme, :string
  validates :theme, inclusion: { in: THEMES.map(&:to_s) }

  store_attribute :settings, :increase_theme_contrast, :boolean
  store_attribute :settings, :force_light_theme_contrast, :boolean
  store_attribute :settings, :force_dark_theme_contrast, :boolean
  store_attribute :settings, :disable_keyboard_shortcuts, :boolean
  store_attribute :settings, :require_double_click_for_inline_edit, :boolean
  store_attribute :settings, :warn_on_leaving_unsaved, :boolean
  store_attribute :settings, :auto_hide_popups, :boolean

  store_attribute :settings, :comments_sorting, :string
  validates :comments_sorting, inclusion: { in: COMMENTS_SORTINGS }

  store_attribute :settings, :diff_type, :string
  validates :diff_type, inclusion: { in: DIFF_TYPES }

  store_attribute :settings, :my_work_view_mode, :string
  validates :my_work_view_mode, inclusion: { in: MY_WORK_VIEW_MODES }, allow_nil: true

  store_attribute :settings, :my_work_mode, :string
  validates :my_work_mode, inclusion: { in: MY_WORK_MODES }, allow_nil: true

  store_attribute :settings, :workdays, :value, default: WORKDAYS_FROM_MONDAY_TO_FRIDAY
  validate :workdays_valid

  store_attribute :settings, :daily_reminders_enabled, :boolean, default: true
  store_attribute :settings, :daily_reminders_times, :value, default: DEFAULT_DAILY_REMINDERS_TIMES
  validate :full_hour_reminder_times

  store_attribute :settings, :immediate_reminders_mentioned, :boolean, default: true
  store_attribute :settings, :immediate_reminders_personal_reminder, :boolean, default: true

  store_attribute :settings, :pause_reminders_enabled, :boolean, default: false
  store_attribute :settings, :pause_reminders_first_day, :date
  store_attribute :settings, :pause_reminders_last_day, :date
  validate :valid_pause_days, if: :pause_reminders_enabled?

  store_attribute :settings, :dismissed_enterprise_banners, :value, default: {}
  store_attribute :settings, :whats_new_read_items, :value, default: {}
  store_attribute :settings, :whats_new_seen_version, :string
  store_attribute :settings, :whats_new_seen_at, :datetime

  class << self
    ##
    # Returns time zones supported by OpenProject. Those include only the subset of all the
    # TZInfo timezones also handled by ActiveSupport::TimeZone.
    # The reason for this is currently:
    #   * the reminder mail implementation which could be amended
    #   * the select in the form which only displays ActiveSupport::TimeZone as they are more
    #     user friendly.
    # As we only store tzinfo compatible data we only provide options, for which the
    # values can later on be retrieved unambiguously. This is not always the case
    # for values in ActiveSupport::TimeZone since multiple AS zones map to single tzinfo zones.
    def assignable_time_zones
      ActiveSupport::TimeZone
        .all
        .group_by { |tz| tz.tzinfo.name }
        .values
        .map do |zones|
        namesake_time_zone(zones)
      end
    end

    private

    # If there are multiple AS::TimeZones for a single TZInfo::Timezone, we
    # only return the one that is the namesake.
    def namesake_time_zone(time_zones)
      if time_zones.length == 1
        time_zones.first
      else
        time_zones.detect { |tz| tz.tzinfo.name.include?(tz.name.tr(" ", "_")) }
      end
    end
  end

  def comments_sorting
    super.presence || OpenProject::Configuration.default_comment_sort_order
  end

  def comments_in_reverse_order?
    comments_sorting == "desc"
  end

  def comments_in_reverse_order=(value)
    self.comments_sorting = to_boolean(value) ? "desc" : "asc"
  end

  def disable_keyboard_shortcuts
    value = super
    value.nil? ? Setting.disable_keyboard_shortcuts? : value
  end

  def diff_type
    super.presence || "inline"
  end

  def auto_hide_popups
    value = super
    value.nil? ? Setting.default_auto_hide_popups? : value
  end

  def warn_on_leaving_unsaved
    value = super
    value.nil? || value
  end

  def require_double_click_for_inline_edit
    super || false
  end

  # Provide an alias to form builders
  alias :comments_in_reverse_order :comments_in_reverse_order?

  def theme
    super.presence || Setting.user_default_theme
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
    read_store_attribute(:settings, :time_zone).present?
  end

  def avatar_color=(value)
    super(value.present? ? ::Colors::HexColor::Normalizer.call(value) : nil)
  end

  def avatar_text=(value)
    super(AvatarTextValidator.normalize(value))
  end

  def daily_reminders_enabled
    value = super
    value.nil? || value
  end

  def daily_reminders_times
    super || DEFAULT_DAILY_REMINDERS_TIMES.dup
  end

  def daily_reminders_times=(value)
    super(Array(value).compact_blank)
  end

  def workdays
    super || WORKDAYS_FROM_MONDAY_TO_FRIDAY.dup
  end

  def workdays=(value)
    super(Array(value).map(&:to_i))
  end

  def immediate_reminders_mentioned
    value = super
    value.nil? || value
  end

  def immediate_reminders_personal_reminder
    value = super
    value.nil? || value
  end

  def pause_reminders_enabled
    super || false
  end

  def pause_reminders_date_range=(value)
    first_day, last_day = value.to_s.split(" - ", 2)
    self.pause_reminders_first_day = first_day
    self.pause_reminders_last_day = last_day
  end

  def dismissed_enterprise_banners
    super || {}
  end

  def dismissed_banner?(feature)
    dismissed_enterprise_banners.key?(feature.to_s)
  end

  def dismiss_banner(feature)
    self.dismissed_enterprise_banners = dismissed_enterprise_banners.merge(feature.to_s => Time.zone.now.utc)
  end

  def whats_new_read_items
    super || {}
  end

  def whats_new_read_keys(version_key)
    whats_new_read_items.fetch(version_key.to_s, [])
  end

  def mark_whats_new_read(version_key, key)
    self.whats_new_read_items = { version_key.to_s => whats_new_read_keys(version_key) | [key.to_s] }
  end

  def mark_whats_new_seen(version_key)
    return if whats_new_seen_version == version_key.to_s

    self.whats_new_seen_version = version_key.to_s
    self.whats_new_seen_at = Time.current
    self.whats_new_read_items = whats_new_read_items.slice(version_key.to_s)
  end

  private

  def to_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def time_zone_assignable
    return unless time_zone?
    return if self.class.assignable_time_zones.any? { |tz| tz.tzinfo.canonical_identifier == time_zone }

    errors.add(:time_zone, :inclusion)
  end

  def workdays_valid
    errors.add(:workdays, :inclusion) unless workdays.all? { |day| ISO_WEEKDAYS.cover?(day) }
    errors.add(:workdays, :no_duplicates) unless workdays.uniq.length == workdays.length
  end

  def full_hour_reminder_times
    unless daily_reminders_times.all? { |time| time.to_s.match?(FULL_HOUR_REMINDER_TIME) }
      errors.add :daily_reminders, :full_hour
    end
  end

  def valid_pause_days
    if pause_reminders_first_day.nil? || pause_reminders_last_day.nil?
      errors.add :pause_reminders, :blank
    elsif pause_reminders_last_day < pause_reminders_first_day
      errors.add :pause_reminders, :invalid_range
    end
  end
end
