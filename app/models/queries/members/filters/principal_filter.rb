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

class Queries::Members::Filters::PrincipalFilter < Queries::Members::Filters::MemberFilter
  include Queries::Filters::Shared::MeValueFilter

  def allowed_values
    @allowed_values ||= begin
      values = Principal
               .not_locked
               .visible
               .map { |s| [s.name, s.id.to_s] }
               .sort

      me_allowed_value + values
    end
  end

  def available?
    allowed_values.any?
  end

  def ar_object_filter?
    true
  end

  def where
    operator_strategy.sql_for_field(values_replaced, self.class.model.table_name, :user_id)
  end

  def type
    :list_optional
  end

  def self.key
    :principal_id
  end
end
