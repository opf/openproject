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

# Selects placeholder users by whether they describe the kind of person they
# stand for. Like the blocked filter, the operator carries the meaning: `=`
# keeps those with criteria, `!` those without.
class Queries::PlaceholderUsers::Filters::HasUserFilterFilter < Queries::PlaceholderUsers::Filters::PlaceholderUserFilter
  def allowed_values
    [[I18n.t(:label_with_criteria), :with_criteria]]
  end

  def type
    :list
  end

  def self.key
    :has_user_filter
  end

  def human_name
    I18n.t(:label_criteria)
  end

  def apply_to(query_scope)
    if operator == "="
      query_scope.where(id: with_criteria)
    else
      query_scope.where.not(id: with_criteria)
    end
  end

  private

  def with_criteria
    PlaceholderUser
      .joins(:placeholder_user_detail)
      .where("placeholder_user_details.user_filter <> '[]'::jsonb")
      .select(:id)
  end
end
