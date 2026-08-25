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

module Backlogs
  # Builds a transient, project-scoped work-package Query for the Backlogs show page.
  class BacklogQueryBuilder
    def initialize(project:, user:, params:)
      @project = project
      @user = user
      @params = params
    end

    def build(extra_filters: [])
      query = Query.new(project: @project, user: @user, include_subprojects: false)

      generic_filters.each { |filter| query.add_filter(filter[:attribute], filter[:operator], filter[:values]) }
      extra_filters.each { |field, operator, values| query.add_filter(field, operator, values) }

      query.sort_criteria = [%w[position asc], %w[id asc]]

      query.valid_subset!
      query
    end

    private

    def generic_filters
      return [] if @params[:filters].blank?

      Queries::ParamsParser.parse(@params).fetch(:filters, [])
    rescue JSON::ParserError
      []
    end
  end
end
