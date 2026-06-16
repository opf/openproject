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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::Meetings::Filters::InvitedUserFilter < Queries::Meetings::Filters::MeetingFilter
  include ::Queries::Filters::Shared::VisiblePrincipalFilter

  def type
    :list_optional
  end

  def type_strategy
    @type_strategy ||= ::Queries::Filters::Strategies::IntegerListOptional.new(self)
  end

  def where # rubocop:disable Metrics/AbcSize
    condition = "#{MeetingParticipant.table_name}.invited"

    case operator
    when "="
      [operator_strategy.sql_for_field(values, MeetingParticipant.table_name, "user_id"), condition].join(" AND ")
    when "!"
      user_id = normalized_user_id(values.first)
      return "1=1" if user_id.nil?

      OpenProject::SqlSanitization.sanitize(<<~SQL.squish, user_id)
        NOT EXISTS (
          SELECT 1 FROM #{MeetingParticipant.table_name}
          WHERE #{MeetingParticipant.table_name}.meeting_id = meetings.id
          AND #{MeetingParticipant.table_name}.user_id = ?
          AND #{condition}
        )
      SQL
    when "*"
      ["#{MeetingParticipant.table_name}.user_id IS NOT NULL", condition].join(" AND ")
    when "!*"
      <<~SQL.squish
        NOT EXISTS (
          SELECT 1 FROM #{MeetingParticipant.table_name}
          WHERE #{MeetingParticipant.table_name}.meeting_id = meetings.id
          AND #{condition}
        )
      SQL
    end
  end

  def human_name
    I18n.t(:label_invited_user)
  end

  def left_outer_joins
    :participants
  end

  def autocomplete_options
    { component: "opce-user-autocompleter", resource: "principals" }
  end

  def self.key
    :invited_user_id
  end

  private

  def normalized_user_id(value)
    Integer(value, 10)
  rescue ArgumentError, TypeError
    nil
  end
end
