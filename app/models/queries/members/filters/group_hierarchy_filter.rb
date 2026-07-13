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

# Like GroupFilter but hierarchy-aware: matches members who are users of the
# given group or any of its descendant groups, as well as the descendant
# groups themselves (which carry inherited Member records).
class Queries::Members::Filters::GroupHierarchyFilter < Queries::Members::Filters::MemberFilter
  def self.key
    :group_hierarchy
  end

  def allowed_values
    @allowed_values ||= ::Group.pluck(:id).map { |g| [g, g.to_s] }
  end

  def available?
    ::Group.exists?
  end

  def type
    :list_optional
  end

  def human_name
    I18n.t("query_fields.member_of_group")
  end

  def joins
    :principal
  end

  def where
    case operator
    when "="
      "users.id IN (#{hierarchy_subselect})"
    when "!"
      "users.id NOT IN (#{hierarchy_subselect})"
    when "*"
      "users.id IN (#{User.within_group([]).select(:id).to_sql})"
    when "!*"
      "users.id NOT IN (#{User.within_group([]).select(:id).to_sql})"
    end
  end

  private

  def hierarchy_subselect
    groups = Group.where(id: values.map(&:to_i))
    all_group_ids = groups.flat_map { |g| g.self_and_descendants.pluck(:id) }.uniq
    user_ids = User.in_group(all_group_ids).pluck(:id)
    (user_ids + all_group_ids).uniq.join(",").presence || "NULL"
  end
end
