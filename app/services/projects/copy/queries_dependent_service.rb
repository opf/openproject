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

module Projects::Copy
  class QueriesDependentService < Dependency
    def self.human_name
      I18n.t(:'projects.copy.queries')
    end

    def source_count
      source.queries.count
    end

    protected

    # Copies queries from +project+
    # Only includes the queries having a view so the ones that are e.g. in:
    # * the work packages table
    # * the team planner
    # * the bcf module
    def copy_dependency(params:)
      mapping = queries_to_copy.map do |query|
        copy = duplicate_query(query, params)
        # Either assign the successfully copied query's ID or nil to indicate
        # it could not be copied.
        new_id = copy.map(&:id).to_a.first

        [query.id, new_id]
      end

      state.query_id_lookup = mapping.to_h
    end

    def queries_to_copy
      source.queries.having_views.includes(:views)
    end

    def duplicate_query(query, params)
      ::Queries::CopyService
        .new(source: query, user:)
        .with_state(state)
        .call(params.merge)
        .on_failure { |result| add_error! query, result.errors }
    end
  end
end
