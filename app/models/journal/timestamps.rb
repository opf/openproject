#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module Journal::Timestamps
  # See: https://github.com/opf/openproject/pull/11243

  extend ActiveSupport::Concern

  class_methods do

    # Select all journals that are the most current at the given timestamp
    # for their respective journables.
    #
    # Suppose, all journables have three journals: One for Monday, one for Wednesday,
    # one for Friday.
    #
    # `at_timestamp(before_monday)` will return none
    # `at_timestamp(monday)` will return the Monday journals
    # `at_timestamp(tuesday)` will return the Monday journals
    # `at_timestamp(wednesday)` will return the Wednesday journals
    # `at_timestamp(thursday)` will return the Wednesday journals
    # `at_timestamp(friday)` will return the Friday journals
    #
    # You may use this to find the journal that represents the data state of
    # a journable at a given timestamp.
    #
    def at_timestamp(timestamp)
      raise ArgumentError, "Expected timestamp to be a Timestamp, an ActiveSupport::TimeWithZone, or a DateTime" unless timestamp.kind_of? Timestamp or timestamp.kind_of? ActiveSupport::TimeWithZone or timestamp.kind_of? DateTime
      timestamp = timestamp.to_time if timestamp.kind_of? Timestamp
      timestamp = timestamp.in_time_zone if timestamp.kind_of? DateTime

      where(id:
        where(created_at: (..timestamp)) \
            .select("distinct on (journable_type, journable_id) id") \
            .reorder(:journable_type, :journable_id, created_at: :desc)
      )
    end

  end
end
