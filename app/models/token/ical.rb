#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Token
  class ICal < HashedToken
    # restrict the usage of one ical token to one query (calendar)
    has_one :ical_token_query_assignment, dependent: :destroy, foreign_key: :ical_token_id
    has_one :query, through: :ical_token_query_assignment
    has_one :project, through: :query

    validate :query_assignment_must_exist

    class << self
      def create_and_return_value(user, query)
        create(user:, query:).plain_value
      end
    end

    def query_assignment_must_exist
      errors.add(:base, "IcalTokenQueryAssignment must exist") unless ical_token_query_assignment.present?
    end
    
    # Prevent deleting previous tokens
    # Every time an ical url is generated, a new ical token will be generated for this url as well
    # the existing ical tokens (and thus urls) should still be valid
    # until the user decides to revert all existing ical tokens (and urls)
    def single_value?
      false
    end
  end
end
