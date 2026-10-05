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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Automations::Actions::Strategies::DateTime
  INPUT_FORMAT = "%Y-%m-%dT%H:%M"

  def values=(values)
    super(Array.wrap(values).map { |v| to_utc_iso8601_or_nil(v) }.uniq)
  end

  def type
    :datetime_property
  end

  def input_value
    time = values.first && Time.iso8601(values.first)

    time&.in_time_zone(User.current.time_zone)&.strftime(INPUT_FORMAT)
  end

  private

  def to_utc_iso8601_or_nil(value)
    time = CustomValue.new(custom_field:, value:).typed_value

    time&.utc&.iso8601
  end
end
