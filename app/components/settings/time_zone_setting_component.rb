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

module Settings
  ##
  # A text field to enter numeric values.
  class TimeZoneSettingComponent < ::ApplicationComponent
    options :form, :title
    options container_class: "-wide"
    options include_blank: true

    # name of setting and tag
    def name
      model
    end

    def render_select
      if form.nil?
        render_setting_select
      else
        render_form_select
      end
    end

    def render_form_select
      form.select(
        name,
        time_zone_entries,
        include_blank:,
        container_class:,
        title:
      )
    end

    def render_setting_select
      helpers.setting_select(
        name,
        time_zone_entries,
        include_blank:,
        container_class:,
        title:
      )
    end

    def time_zone_entries
      UserPreferences::UpdateContract
        .assignable_time_zones
        .group_by { |tz| tz.tzinfo.canonical_zone }
        .map { |canonical_zone, included_zones| time_zone_option(canonical_zone, included_zones) }
    end

    private

    def time_zone_option(canonical_zone, zones)
      zone_names = zones.map(&:name).join(", ")
      [
        "(UTC#{ActiveSupport::TimeZone.seconds_to_utc_offset(canonical_zone.base_utc_offset)}) #{zone_names}",
        canonical_zone.identifier
      ]
    end
  end
end
