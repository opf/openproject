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

require "spec_helper"

RSpec.describe MockedPermissionHelper do
  let(:user) { build(:user) }
  let(:project) { build(:project) }
  let(:other_project) { build(:project) }
  let(:work_package_in_project) { build(:work_package, project:) }
  let(:other_work_package_in_project) { build(:work_package, project:) }
  let(:other_work_package) { build(:work_package) }
  let(:project_query) { build(:project_query) }

  context "when trying to mock a permission that does not exist" do
    it "raises UnknownPermissionError exception" do
      expect do
        mock_permissions_for(user) do |mock|
          mock.allow_globally :this_permission_does_not_exist
        end
      end.to raise_error(Authorization::UnknownPermissionError)
    end
  end

  context "when trying to mock a permission in the wrong context" do
    it "raises IllegalPermissionContext exception" do
      expect do
        mock_permissions_for(user) do |mock|
          mock.allow_globally :view_work_packages # this is a project/work_package permission
        end
      end.to raise_error(Authorization::IllegalPermissionContextError)
    end
  end

  context "when trying to mock a permission on nil as the project" do
    it "raises an ArgumentError exception" do
      expect do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :view_work_packages, project: nil
        end
      end.to raise_error(ArgumentError, /tried to mock a permission on nil/)
    end
  end

  context "when trying to mock a permission on nil as the work package" do
    it "raises an ArgumentError exception" do
      expect do
        mock_permissions_for(user) do |mock|
          mock.allow_in_work_package :view_work_packages, work_package: nil
        end
      end.to raise_error(ArgumentError, /tried to mock a permission on nil/)
    end
  end

  context "when trying to mock a permission on nil as the project query" do
    it "raises an ArgumentError exception" do
      expect do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project_query :view_project_query, project_query: nil
        end
      end.to raise_error(ArgumentError, /tried to mock a permission on nil/)
    end
  end

  context "when not providing a block" do
    it "does not allow anything" do
      expect do
        mock_permissions_for(user)
      end.to raise_error(ArgumentError)
    end
  end

  context "when explicitly forbidding everything" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_everything
        mock.allow_globally :add_project
        mock.allow_in_project(:add_work_packages, project:)
        mock.allow_in_project_query(:view_project_query, project_query:)

        # this removes all permissions previously set
        mock.forbid_everything
      end
    end

    it "does not allow anything" do
      expect(user).not_to be_allowed_globally(:add_project)
      expect(user).not_to be_allowed_in_project(:add_work_packages, project)
      expect(user).not_to be_allowed_in_any_project(:add_work_packages)
      expect(user).not_to be_allowed_in_work_package(:add_work_packages, work_package_in_project)
      expect(user).not_to be_allowed_in_any_work_package(:add_work_packages)
      expect(user).not_to be_allowed_in_project_query(:view_project_query, project_query)
      expect(user).not_to be_allowed_in_any_project_query(:view_project_query)
    end
  end

  context "when mocking all permissions" do
    before do
      mock_permissions_for(user, &:allow_everything)
    end

    it "allows everything" do
      expect(user).to be_allowed_globally(:add_project)
      expect(user).to be_allowed_in_project(:add_work_packages, project)
      expect(user).to be_allowed_in_any_project(:add_work_packages)
      expect(user).to be_allowed_in_work_package(:add_work_packages, work_package_in_project)
      expect(user).to be_allowed_in_any_work_package(:add_work_packages)
      expect(user).to be_allowed_in_project_query(:view_project_query, project_query)
      expect(user).to be_allowed_in_any_project_query(:view_project_query)
    end
  end

  context "when running the mock service multiple times" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_globally :add_project
      end

      # this will overwrite the mocks from the first run
      mock_permissions_for(user) do |mock|
        mock.allow_globally :manage_user
      end
    end

    it "only allows the permissions from the last run" do
      expect(user).not_to be_allowed_globally(:add_project)
      expect(user).to be_allowed_globally(:manage_user)
    end
  end

  context "when mocking a global permission" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_globally :add_project
      end
    end

    it "allows the global permission" do
      expect(user).to be_allowed_globally(:add_project)
    end

    it "allows the global permission when querying with controller and action hash" do
      expect(user).to be_allowed_globally({ controller: "projects", action: "new" })
    end
  end

  context "when mocking a permission in the project" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project :view_work_packages, :add_work_packages, project:
      end
    end

    it "allows the permissions when asking for the project" do
      expect(user).to be_allowed_in_project(:view_work_packages, project)
      expect(user).not_to be_allowed_in_project(:view_work_packages, other_project)

      expect(user).to be_allowed_in_project(:add_work_packages, project)
      expect(user).not_to be_allowed_in_project(:add_work_packages, other_project)
    end

    it "allows the project permission when querying with controller and action hash" do
      expect(user).to be_allowed_in_project({ controller: "work_packages", action: "index", project_id: project.id }, nil)
      expect(user).to be_allowed_in_any_project({ controller: "work_packages", action: "index" })
    end

    it "allows the permissions when asking for any project" do
      expect(user).to be_allowed_in_any_project(:view_work_packages)
      expect(user).to be_allowed_in_any_project(:add_work_packages)
    end

    it "allows the permissions when asking for any work package within the project" do
      expect(user).to be_allowed_in_any_work_package(:view_work_packages, in_project: project)
      expect(user).not_to be_allowed_in_any_work_package(:view_work_packages, in_project: other_project)

      expect(user).to be_allowed_in_any_work_package(:add_work_packages, in_project: project)
      expect(user).not_to be_allowed_in_any_work_package(:add_work_packages, in_project: other_project)
    end

    it "allows the permissions when asking for any work package" do
      expect(user).to be_allowed_in_any_work_package(:view_work_packages)
      expect(user).to be_allowed_in_any_work_package(:add_work_packages)

      expect(user).not_to be_allowed_in_any_work_package(:copy_work_packages)
    end

    it "allows the permission when asking for a specific work package within the project" do
      expect(user).to be_allowed_in_work_package(:view_work_packages, work_package_in_project)
      expect(user).not_to be_allowed_in_work_package(:view_work_packages, other_work_package)
    end
  end

  context "when mocking a permission in the work package" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_work_package :view_work_packages, work_package: work_package_in_project
        mock.allow_in_work_package :view_work_packages, :edit_work_packages, work_package: other_work_package_in_project
      end
    end

    it "does not allow the permissions when asking for the project" do
      expect(user).not_to be_allowed_in_project(:view_work_packages, project)
    end

    it "does not allow the permissions when asking for any project" do
      expect(user).not_to be_allowed_in_any_project(:view_work_packages)
      expect(user).not_to be_allowed_in_any_project(:edit_work_packages)
    end

    it "allows the permissions when asking for any work package within the project" do
      expect(user).to be_allowed_in_any_work_package(:view_work_packages, in_project: project)
      expect(user).not_to be_allowed_in_any_work_package(:view_work_packages, in_project: other_project)

      expect(user).to be_allowed_in_any_work_package(:edit_work_packages, in_project: project)
      expect(user).not_to be_allowed_in_any_work_package(:edit_work_packages, in_project: other_project)

      expect(user).not_to be_allowed_in_any_work_package(:copy_work_packages, in_project: project)
    end

    it "allows the work package permission when querying with controller and action hash" do
      expect(user).to be_allowed_in_work_package({ controller: "work_packages", action: "index", project_id: project.id },
                                                 work_package_in_project)
      expect(user).to be_allowed_in_any_work_package({ controller: "work_packages", action: "index", project_id: project.id })
      expect(user).to be_allowed_in_any_work_package({ controller: "work_packages", action: "index", project_id: project.id },
                                                     in_project: project)
    end

    it "allows the permissions when asking for any work package" do
      expect(user).to be_allowed_in_any_work_package(:view_work_packages)
      expect(user).to be_allowed_in_any_work_package(:edit_work_packages)

      expect(user).not_to be_allowed_in_any_work_package(:copy_work_packages)
    end

    it "allows the permission when asking for a specific work package within the project" do
      expect(user).to be_allowed_in_work_package(:view_work_packages, work_package_in_project)
      expect(user).to be_allowed_in_work_package(:view_work_packages, other_work_package_in_project)
      expect(user).not_to be_allowed_in_work_package(:view_work_packages, other_work_package)

      expect(user).not_to be_allowed_in_work_package(:edit_work_packages, work_package_in_project)
      expect(user).to be_allowed_in_work_package(:edit_work_packages, other_work_package_in_project)
      expect(user).not_to be_allowed_in_work_package(:edit_work_packages, other_work_package)
    end
  end
end
