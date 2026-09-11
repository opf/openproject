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

class Queries::WorkPackages::Filter::AuthorFilter <
    Queries::WorkPackages::Filter::PrincipalBaseFilter
  def allowed_values
    @author_values ||= me_allowed_value + principal_loader.principal_values
  end

  def type
    :list
  end

  def self.key
    :author_id
  end

  def where
    expanded_values = expand_group_values(values_replaced)
    operator_strategy.sql_for_field(expanded_values, self.class.model.table_name, self.class.key)
  end

  private

  def autocomplete_principal_types
    %w[User]
  end

  def expand_group_values(values)
    return values if values.empty?

    group_ids = Group.where(id: values).pluck(:id).map(&:to_s)
    user_ids  = values - group_ids

    if group_ids.any?
      group_member_ids = User
                           .joins(:groups)
                           .where(groups_users: { id: group_ids })
                           .pluck(:id)
                           .map(&:to_s)
      user_ids += group_member_ids
    end

    user_ids.uniq
  end
end
