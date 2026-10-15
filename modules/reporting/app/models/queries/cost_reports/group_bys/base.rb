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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Base class for all cost report group bys.
#
# A group by only names a dimension the report aggregates over. Which axis it is
# rendered on is view state and lives on the CostReport view, not here. The
# grouping SQL is built by the reporting engine from the equally named
# CostQuery::GroupBy::* class.
class Queries::CostReports::GroupBys::Base < Queries::GroupBys::Base
  self.model = TimeEntry

  def self.key
    to_s.demodulize.underscore.to_sym
  end

  # The engine addresses its group bys by the demodulized, camelized name, e.g.
  # :work_package_id -> CostQuery::GroupBy::WorkPackageId
  def engine_group_by
    "CostQuery::GroupBy::#{name.to_s.camelize}".constantize
  end

  def caption
    engine_group_by.label
  end

  def apply_to(_query_scope)
    raise NotImplementedError, "Cost report group bys are applied by the reporting engine" # rubocop:disable OpenProject/NoNotImplementedError
  end
end
