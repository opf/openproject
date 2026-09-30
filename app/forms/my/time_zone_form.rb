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

class My::TimeZoneForm < ApplicationForm
  form do |f|
    f.select_list(
      name: :time_zone,
      label: attribute_name(:time_zone),
      required: true,
      include_blank: false,
      input_width: :large
    ) do |list|
      available_time_zones.each do |label, value|
        list.option(label:, value:)
      end
    end
  end

  private

  def available_time_zones
    @available_time_zones ||= UserPreferences::UpdateContract
      .assignable_time_zones
      .group_by { it.tzinfo.canonical_zone }
      .map { |canonical_zone, included_zones| build_time_zone_entry(canonical_zone, included_zones) }
  end

  def build_time_zone_entry(canonical_zone, zones)
    zone_names = zones.map(&:name).join(", ")
    offset = ActiveSupport::TimeZone.seconds_to_utc_offset(canonical_zone.base_utc_offset)

    ["(UTC#{offset}) #{zone_names}", canonical_zone.identifier]
  end
end
