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
module BasicData
  class StatusSeeder < ModelSeeder
    self.model_class = Status
    self.seed_data_model_key = "statuses"
    self.attribute_names_for_lookups = %i[name is_closed is_default]
    self.needs = [
      BasicData::ColorSeeder,
      BasicData::ColorSchemeSeeder
    ]

    def model_attributes(status_data)
      {
        name: status_data["name"],
        color_id: color_id(status_data["color_name"]),
        default_done_ratio: status_data["default_done_ratio"] || 0,
        is_closed: true?(status_data["is_closed"]),
        is_default: true?(status_data["is_default"]),
        position: status_data["position"]
      }
    end
  end
end
