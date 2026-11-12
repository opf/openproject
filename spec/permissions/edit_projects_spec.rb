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

# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe "edit_project permission", type: :controller do
  include PermissionSpecs

  describe Projects::SettingsController do
    describe Projects::Settings::GeneralController do
      check_permission_required_for("projects/settings/general#show", :edit_project)
      check_permission_required_for("projects/settings/general#update", :edit_project)
      check_permission_required_for("projects/settings/general#toggle_public", :edit_project)
      check_permission_required_for("projects/settings/general#toggle_public_dialog", :edit_project)
    end

    describe Projects::Settings::StorageController do
      check_permission_required_for("projects/settings/storage#show", :edit_project)
    end

    describe Projects::Settings::WorkPackagesController do
      check_permission_required_for("projects/settings/work_packages#show", :edit_project)

      describe Projects::Settings::WorkPackages::InternalCommentsController do
        check_permission_required_for("projects/settings/work_packages/internal_comments#show", :edit_project)
        check_permission_required_for("projects/settings/work_packages/internal_comments#update", :edit_project)
      end
    end
  end

  describe Projects::TemplatedController do
    check_permission_required_for("projects/templated#create", :edit_project)
    check_permission_required_for("projects/templated#destroy", :edit_project)
  end

  describe Projects::IdentifierController do
    check_permission_required_for("projects/identifier#show", :edit_project)
    check_permission_required_for("projects/identifier#update", :edit_project)
  end

  describe Projects::StatusController do
    check_permission_required_for("projects/status#update", :edit_project)
    check_permission_required_for("projects/status#destroy", :edit_project)
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
