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

class Queries::Members::Filters::ProjectFilter < Queries::Members::Filters::MemberFilter
  include Queries::Filters::Shared::ProjectFilter::Optional

  # Global memberships have no project to be identified by, so they are selected
  # alongside project ids through this sentinel.
  GLOBAL_VALUE = "global"

  def where
    return super unless global?

    clauses = ["#{Member.table_name}.project_id IS NULL"]
    clauses << operator_strategy.sql_for_field(project_ids, Member.table_name, self.class.key) if project_ids.any?

    clauses.join(" OR ")
  end

  def validate_values
    return super unless global?

    errors.add(:values, :invalid) unless project_ids.all? { /\A\d+\z/.match?(it.to_s) }
  end

  private

  def global?
    values.include?(GLOBAL_VALUE)
  end

  def project_ids
    values - [GLOBAL_VALUE]
  end
end
