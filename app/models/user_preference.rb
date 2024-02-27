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

class UserPreference < ApplicationRecord
  belongs_to :user
  delegate :notification_settings, to: :user
  serialize :settings, coder: ::Serializers::IndifferentHashSerializer

  validates :user,
            presence: true

  WORKDAYS_FROM_MONDAY_TO_FRIDAY = [1, 2, 3, 4, 5].freeze

  ##
  # Retrieve keys from settings, and allow accessing
  # as boolean with ? suffix
  def method_missing(method_name, *args)
    key = method_name.to_s
    return super unless supported_settings_method?(key)

    action = key[-1]

    case action
    when '?'
      to_boolean send(key[..-2])
    when '='
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
    comments_sorting == 'desc'
  end

  def diff_type
    settings.fetch(:diff_type, 'inline')
  end

  def hide_mail
    settings.fetch(:hide_mail, true)
  end

  def can_expose_mail?
    !hide_mail
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

  def comments_in_reverse_order=(value)
    settings[:comments_sorting] = to_boolean(value) ? 'desc' : 'asc'
  end

  def theme
    super.presence || Setting.user_default_theme
  end

  def high_contrast_theme?
    theme.end_with?('high_contrast')
  end

  def time_zone
    super.presence || Setting.user_default_timezone.presence
  end

  def daily_reminders
    super.presence || { enabled: true, times: ["08:00:00+00:00"] }.with_indifferent_access
  end

  def workdays
    super || WORKDAYS_FROM_MONDAY_TO_FRIDAY
  end

  def immediate_reminders
    super.presence || { mentioned: true }.with_indifferent_access
  end

  def pause_reminders
    super.presence || { enabled: false }.with_indifferent_access
  end

  def supported_settings_method?(method_name)
    UserPreferences::Schema.properties.include?(method_name.to_s.gsub(/\?|=\z/, ''))
  end

  private

  def to_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end

  def attribute?(name)
    %i[user user_id].include?(name.to_sym)
  end
end
