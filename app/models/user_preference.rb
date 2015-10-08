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

class UserPreference < ActiveRecord::Base
  belongs_to :user
  serialize :others

  validates_presence_of :user
  validate :time_zone_correctness, if: -> { time_zone.present? }
  validate :theme_correctness, if: -> { theme.present? }

  after_initialize :init_other_preferences

  def [](attr_name)
    attribute_present?(attr_name) ? super : others[attr_name]
  end

  def []=(attr_name, value)
    attribute_present?(attr_name) ? super : others[attr_name] = value
  end

  def comments_sorting
    others[:comments_sorting]
  end

  def comments_sorting=(order)
    others[:comments_sorting] = order
  end

  def comments_in_reverse_order?
    comments_sorting == 'desc'
  end

  def warn_on_leaving_unsaved?
    # Need to cast here as previous values were '0' / '1'
    to_boolean(others.fetch(:warn_on_leaving_unsaved) { true })
  end

  def warn_on_leaving_unsaved=(value)
    others[:warn_on_leaving_unsaved] = to_boolean(value)
  end

  # Provide an alias to form builders
  alias :comments_in_reverse_order :comments_in_reverse_order?
  alias :warn_on_leaving_unsaved :warn_on_leaving_unsaved?

  def comments_in_reverse_order=(value)
    others[:comments_sorting] = to_boolean(value) ? 'desc' : 'asc'
  end

  def theme
    others[:theme] || OpenProject::Themes.application_theme_identifier
  end

  def theme=(identifier)
    others[:theme] = identifier.nil? ? nil : identifier.to_sym
  end

  def canonical_time_zone
    return if time_zone.nil?

    zone = ActiveSupport::TimeZone.new(time_zone)
    unless zone.nil?
      zone.tzinfo.canonical_identifier
    end
  end

  def impaired?
    !!impaired
  end

  def warn_on_leaving_unsaved?
    # Need to cast here as previous values were '0' / '1'
    to_boolean(others.fetch(:warn_on_leaving_unsaved) { true })
  end

  def warn_on_leaving_unsaved
    warn_on_leaving_unsaved?
  end

  def warn_on_leaving_unsaved=(value)
    others[:warn_on_leaving_unsaved] = to_boolean(value)
  end

  private

  def to_boolean(value)
    ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end

  def init_other_preferences
    self.others ||= { no_self_notified: true }
  end

  def time_zone_correctness
    errors.add(:time_zone, :inclusion) if time_zone.present? && canonical_time_zone.nil?
  end

  def theme_correctness
    return true if theme == OpenProject::Themes.application_theme_identifier
    themes = OpenProject::Themes.all.map(&:identifier)

    unless themes.any? { |identifier| theme.to_sym == identifier }
      errors.add(:theme, :inclusion)
    end
  end
end
