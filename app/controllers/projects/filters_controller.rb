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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::FiltersController < ApplicationController
  include Queries::Loading

  # This is a part of the projects list page which is public. Checks within filters will
  # prevent sensitive information to be displayed wrongfully.
  no_authorization_required! :show
  before_action :load_query_or_deny_access

  def show
    render Projects::ProjectsFiltersComponent.new(query: @query), layout: false
  end

  private

  # Overwrite method in Queries::Loading
  # as the default of using the controller name does not apply.
  def query_class
    ::ProjectQuery
  end
end
