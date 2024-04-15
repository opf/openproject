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
#
module Query::Timestamps
  extend ActiveSupport::Concern

  included do
    serialize :timestamps, type: Array

    # Returns the timestamps the query should be evaluated at.
    #
    # In the database, the timestamps are stored as strings.
    # This method returns the timestamps as array of `Timestamp` objects.
    #
    # Timestamps can be absolute (e.g. a certain date and time) or relative
    # (e.g. three weeks ago). To convert a timestamp to a absolute time,
    # call `timestamp.to_time`.
    #
    def timestamps
      timestamps = super.collect do |timestamp_string|
        Timestamp.new(timestamp_string)
      end
      timestamps.any? ? timestamps : [Timestamp.now]
    end

    def timestamps=(params)
      super(Array(params).collect(&:to_s))
    end

    # Does this query perform a historic search?
    #
    def historic?
      timestamps != [Timestamp.now]
    end
  end
end
