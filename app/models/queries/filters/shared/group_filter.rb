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

module Queries::Filters::Shared::GroupFilter
  def self.included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  module InstanceMethods
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

    def where
      case operator
      when "="
        "users.id IN (#{group_subselect})"
      when "!"
        "users.id NOT IN (#{group_subselect})"
      when "*"
        "users.id IN (#{any_group_subselect})"
      when "!*"
        "users.id NOT IN (#{any_group_subselect})"
      end
    end

    private

    def group_subselect
      User.in_group(values).select(:id).to_sql
    end

    def any_group_subselect
      User.within_group([]).select(:id).to_sql
    end
  end

  module ClassMethods
    def key
      :group
    end
  end
end
