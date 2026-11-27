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

require "ttfunk"

class CustomStyle < ApplicationRecord
  LOGO_FIELDS = {
    desktop: {
      light: :logo,
      light_high_contrast: :logo_light_high_contrast,
      dark: :logo_dark
    },
    mobile: {
      light: :logo_mobile,
      light_high_contrast: :logo_mobile_light_high_contrast,
      dark: :logo_mobile_dark
    }
  }.freeze

  ASSET_FIELDS = (LOGO_FIELDS.values.flat_map(&:values) +
    %i[export_logo export_cover export_footer favicon touch_icon
       export_font_regular export_font_bold export_font_italic export_font_bold_italic]).freeze

  before_save { assets.each_value(&:write_identifier) }
  after_save { assets.each_value(&:store) }
  before_destroy :schedule_asset_deletions

  class << self
    def current
      RequestStore.fetch(:current_custom_style) do
        custom_style = CustomStyle.order(Arel.sql("created_at DESC")).first
        if custom_style.nil?
          return nil
        else
          custom_style
        end
      end
    end
  end

  def digest
    updated_at.to_i
  end

  def logo_for(color_mode:, high_contrast: false, mobile: false)
    fields = LOGO_FIELDS.fetch(mobile ? :mobile : :desktop)
    variant = color_mode.to_sym == :light && high_contrast ? :light_high_contrast : color_mode.to_sym
    requested_logo = public_send(fields.fetch(variant))

    requested_logo.presence || public_send(fields.fetch(:light))
  end

  ASSET_FIELDS.each do |name|
    define_method(name) { assets[name] ||= CustomStyleAsset.new(self, name) }
    define_method(:"#{name}=") { |input| public_send(name).assign(input) }
    define_method(:"#{name}_identifier") { public_send(name).identifier }
    define_method(:"#{name}_path") { public_send(name).local_path }
    define_method(:"remove_#{name}=") do |value|
      public_send(name).assign(nil) if ActiveModel::Type::Boolean.new.cast(value)
    end
    define_method(:"remove_#{name}!") { update!(name => nil) }
  end

  def reload(...)
    assets.clear
    super
  end

  private

  def initialize_dup(other)
    super
    @assets = {}
    ASSET_FIELDS.each { |field| self[field] = nil }
  end

  def schedule_asset_deletions
    stored = self.class.lock.find(id)
    ASSET_FIELDS.each { |field| public_send(field).schedule_deletion(stored[field]) }
  end

  def assets
    @assets ||= {}
  end
end
