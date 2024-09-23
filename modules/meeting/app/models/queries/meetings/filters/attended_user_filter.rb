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

class Queries::Meetings::Filters::AttendedUserFilter < Queries::Meetings::Filters::MeetingFilter
  def type
    :list_optional
  end

  def type_strategy
    # Instead of getting the IDs of all the projects a user is allowed
    # to see we only check that the value is an integer.  Non valid ids
    # will then simply create an empty result but will not cause any
    # harm.
    @type_strategy ||= ::Queries::Filters::Strategies::IntegerListOptional.new(self)
  end

  def where
    "meeting_participants.user_id IN (#{values.join(',')}) AND meeting_participants.attended"
  end

  def joins
    :participants
  end

  def self.key
    :attended_user_id
  end

  def available_operators
    [::Queries::Operators::Equals]
  end
end
