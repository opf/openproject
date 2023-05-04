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

class IcalTokenQueryAssignment < ApplicationRecord
  # TODO: dependent_destroy from query model? --> already defined on database level
  belongs_to :ical_token, class_name: 'Token::ICal'
  belongs_to :query

  validates :name, presence: true
  validate :unique_name_per_user_and_query

  attr_accessor :user_id

  def ical_token_user_id
    # when creating an ical_token with nested params for ical_token_query_assignment
    # the user_id from the parent ical_token is not accessible
    # thererfore we need to pass it as an attribute like
    # Token::ICal.create(
    #   user: user,
    #   ical_token_query_assignment_attributes: { query: query, name: name, user_id: user.id }
    # )
    # ical_token.user_id is nil in this case and unique_name_per_user_and_query would fail
    # we therefore use the explicit user_id attribute
    #
    # when the ical_token and assignment are already created
    # we can access the user_id of the ical_token directly instead
    ical_token&.user_id || user_id
  end

  def unique_name_per_user_and_query
    name_already_taken_for_query_and_user = self.class.joins(ical_token: :user)
      .where(name: name, query_id: query_id, ical_token: { user_id: ical_token_user_id })
      .exists?

    if name_already_taken_for_query_and_user
      errors.add(:name, "has already been taken for this query and user")
    end
  end
end
