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

class Queries::Members::Filters::AlsoProjectMemberFilter < Queries::Members::Filters::MemberFilter
  include Queries::Filters::Shared::BooleanFilter

  def where
    if allowed_values.first.intersect?(values)
      "EXISTS (#{project_member_subquery})"
    else
      "NOT EXISTS (#{project_member_subquery})"
    end
  end

  def available_operators
    [::Queries::Operators::BooleanEquals]
  end

  def type_strategy
    @type_strategy ||= ::Queries::Filters::Strategies::BooleanListStrict.new self
  end

  private

  def project_member_subquery
    <<~SQL.squish
      SELECT 1 FROM "members" as "project_members"
      WHERE
        project_members.user_id = members.user_id AND
        project_members.project_id = members.project_id AND
        project_members.entity_type IS NULL AND
        project_members.entity_id IS NULL AND
        project_members.id != members.id
    SQL
  end
end
