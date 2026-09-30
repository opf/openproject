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

require "spec_helper"
require "support/permission_specs"

RSpec.describe Overviews::OverviewsController, "edit_project_phases permission", # rubocop:disable RSpec/EmptyExampleGroup,RSpec/SpecFilePathFormat
               type: :controller do
  include PermissionSpecs

  # render dialog with inputs for editing project attributes with edit_project permission
  check_permission_required_for("overviews/project_phases#edit", :edit_project_phases)

  # render form with inputs for editing project attributes with edit_project permission
  check_permission_required_for("overviews/project_phases#preview", :edit_project_phases)

  # update project attributes with edit_project permission, deeper permission check via contract in place
  check_permission_required_for("overviews/project_phases#update", :edit_project_phases)
end
