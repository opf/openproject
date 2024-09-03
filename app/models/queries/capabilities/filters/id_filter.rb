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

class Queries::Capabilities::Filters::IdFilter < Queries::Capabilities::Filters::CapabilityFilter
  include Queries::Filters::Shared::ParsedFilter

  private

  def split_values
    values.map do |value|
      if (matches = value.match(/\A(\w+\/\w+)\/([pg])(\d*)-(\d+)\z/))
        {
          action: matches[1],
          context_key: matches[2],
          context_id: matches[3],
          principal_id: matches[4]
        }
      end
    end
  end

  def value_conditions
    split_values.map do |value|
      conditions = ["action = '#{value[:action]}' AND principal_id = #{value[:principal_id]}"]

      conditions << if value[:context_id].present?
                      ["context_id = #{value[:context_id]}"]
                    else
                      ["context_id IS NULL"]
                    end

      "(#{conditions.join(' AND ')})"
    end
  end
end
