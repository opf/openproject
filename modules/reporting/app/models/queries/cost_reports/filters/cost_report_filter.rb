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

# Base class for all cost report filters.
#
# These filters only carry the filter definition - attribute, operator and
# values. The SQL is built by the reporting engine (Report::Chainable and
# friends) from the equally named CostQuery::Filter::* class, so none of the
# subclasses implement #where or #joins.
class Queries::CostReports::Filters::CostReportFilter < Queries::Filters::Base
  self.model = TimeEntry

  # The engine addresses its filters by the demodulized, camelized name, e.g.
  # :work_package_id -> CostQuery::Filter::WorkPackageId
  def engine_filter
    "CostQuery::Filter::#{name.to_s.camelize}".constantize
  end

  def human_name
    engine_filter.label
  end

  def where
    raise NotImplementedError, "Cost report filters are applied by the reporting engine" # rubocop:disable OpenProject/NoNotImplementedError
  end
end
