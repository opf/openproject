# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

class MeetingQueries::Static
  UPCOMING = "upcoming".freeze
  PAST = "past".freeze
  UPCOMING_INVITATIONS = "upcoming_invitations".freeze
  PAST_INVITATIONS = "past_invitations".freeze
  ATTENDEE = "attendee".freeze
  CREATOR = "creator".freeze

  DEFAULT = UPCOMING

  class << self
    def query(id)
      case id
      when UPCOMING
        static_query_upcoming
      when PAST
        static_query_past
      when UPCOMING_INVITATIONS, nil
        static_query_upcoming_invitations
      when PAST_INVITATIONS
        static_query_past_invitations
      when ATTENDEE
        static_query_attendee
      when CREATOR
        static_query_creator
      end
    end

    private

    def static_query_upcoming
      list_with(:label_upcoming_meetings) do |query|
        query.where("time", "=", ["future"])
        query.order(start_time: :asc)
      end
    end

    def static_query_past
      list_with(:label_past_meetings) do |query|
        query.where("time", "=", ["past"])
        query.order(start_time: :desc)
      end
    end

    def static_query_upcoming_invitations
      list_with(:label_upcoming_invitations) do |query|
        query.where("time", "=", ["future"])
        query.where("invited_user_id", "=", [User.current.id.to_s])
        query.order(start_time: :asc)
      end
    end

    def static_query_past_invitations
      list_with(:label_past_invitations) do |query|
        query.where("time", "=", ["past"])
        query.where("invited_user_id", "=", [User.current.id.to_s])
        query.order(start_time: :desc)
      end
    end

    def static_query_attendee
      list_with(:label_attendee) do |query|
        query.where("attended_user_id", "=", [User.current.id.to_s])
        query.order(start_time: :asc)
      end
    end

    def static_query_creator
      list_with(:label_creator) do |query|
        query.where("author_id", "=", [User.current.id.to_s])
        query.order(start_time: :asc)
      end
    end

    def list_with(name, &)
      MeetingQuery.new(name: I18n.t(name)).tap(&)
    end
  end
end
