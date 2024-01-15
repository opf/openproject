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

##
# An extension to the SqlBypass class to store
# sessions in database without going through ActiveRecord
module Sessions
  class SqlBypass < ::ActiveRecord::SessionStore::SqlBypass
    class << self
      ##
      # Looks up session data for a given session ID.
      #
      # This is not specific to AR sessions which are stored as AR records.
      # But this is the probably the first place one would search for session-related
      # methods. I.e. this works just as well for cache- and file-based sessions.
      #
      # @param session_id [String] The session ID as found in the `_open_project_session` cookie
      # @return [Hash] The saved session data (user_id, updated_at, etc.) or nil if no session was found.
      def lookup_data(session_id)
        rack_session = Rack::Session::SessionId.new(session_id)
        find_by_session_id(rack_session.private_id)&.data
      end

      def connection_pool
        ::ActiveRecord::Base.connection_pool
      end

      def connection
        ::ActiveRecord::Base.connection
      end
    end

    # Ensure we use our own class methods for delegation of the connection
    # otherwise the memoized superclass is being used
    delegate :connection, :connection_pool, to: :class

    ##
    # Save while updating the user_id reference and updated_at column
    def save
      return false unless loaded?

      if @new_record
        insert!
      else
        update!
      end
    end

    private

    def user_id
      id = data.with_indifferent_access['user_id'].to_i
      id > 0 ? id : nil
    end

    def insert!
      @new_record = false
      connection.update <<~SQL, 'Create session'
         INSERT INTO sessions (session_id, data, user_id, updated_at)
         VALUES (
           #{connection.quote(session_id)},
           #{connection.quote(self.class.serialize(data))},
           #{connection.quote(user_id)},
           (now() at time zone 'utc')
        )
      SQL
    end

    def update!
      connection.update <<~SQL, 'Update session'
        UPDATE sessions
        SET
          data=#{connection.quote(self.class.serialize(data))},
          session_id=#{connection.quote(session_id)},
          user_id=#{connection.quote(user_id)},
          updated_at=(now() at time zone 'utc')
        WHERE session_id=#{connection.quote(@retrieved_by)}
      SQL
    end
  end
end
