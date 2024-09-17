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

class ICalTokenQueryAssignment < ApplicationRecord
  self.table_name = "ical_token_query_assignments"

  belongs_to :ical_token, class_name: "Token::ICal", optional: true
  belongs_to :query, optional: true
  validates :name, presence: true
  validate :unique_name_per_user_and_query

  def unique_name_per_user_and_query
    if ical_token.nil? || ical_token.user_id.nil?
      raise "Cannot validate uniqueness of name for #{self.class} without ical_token.user_id"
    end

    name_already_taken_for_query_and_user = self.class.joins(:ical_token)
      .exists?(name:, query_id:, ical_token: { user_id: ical_token.user_id })

    if name_already_taken_for_query_and_user
      errors.add(:name, :not_unique)
    end
  end
end
