# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe User, ".execute_as_admin" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:user, reload: true) { create(:user) }
  shared_let(:project, reload: true) { create(:project) }

  context "for a project permission" do
    shared_examples "no permissions granted" do
      it "still disallows the action in the project", :aggregate_failures do
        expect(user)
          .not_to be_allowed_in_project(:view_work_packages, project)

        described_class.execute_as_admin(user) do
          expect(user)
            .not_to be_allowed_in_project(:view_work_packages, project)
        end

        expect(user)
          .not_to be_allowed_in_project(:view_work_packages, project)
      end

      it "does not return projects in the .allowed_to scope", :aggregate_failures do
        expect(Project.allowed_to(user, :view_work_packages))
          .to be_empty

        described_class.execute_as_admin(user) do
          expect(Project.allowed_to(user, :view_work_packages))
            .to be_empty
        end

        expect(Project.allowed_to(user, :view_work_packages))
          .to be_empty
      end
    end

    context "with the permission's module being enabled" do
      it "allows actions within the project the user normally doesn't have", :aggregate_failures do
        expect(user)
          .not_to be_allowed_in_project(:view_work_packages, project)

        described_class.execute_as_admin(user) do
          expect(user)
            .to be_allowed_in_project(:view_work_packages, project)
        end

        expect(user)
          .not_to be_allowed_in_project(:view_work_packages, project)
      end

      it "returns projects for which the user normally doesn't have permissions when using the .allowed_to scope",
         :aggregate_failures do
        expect(Project.allowed_to(user, :view_work_packages))
          .to be_empty

        described_class.execute_as_admin(user) do
          expect(Project.allowed_to(user, :view_work_packages))
            .to match [project]
        end

        expect(Project.allowed_to(user, :view_work_packages))
          .to be_empty
      end
    end

    context "with the permission's module being disabled" do
      before do
        project.enabled_module_names = []
        project.save
      end

      it_behaves_like "no permissions granted"
    end

    context "with the project being archived" do
      before do
        project.active = false
        project.save
      end

      it_behaves_like "no permissions granted"
    end

    context "with the user being inactive" do
      before do
        user.locked!
      end

      it_behaves_like "no permissions granted"
    end
  end

  context "for a global permission" do
    it "allows actions globally the user normally doesn't have", :aggregate_failures do
      expect(user)
        .not_to be_allowed_globally(:add_project)

      described_class.execute_as_admin(user) do
        expect(user)
          .to be_allowed_globally(:add_project)
      end

      expect(user)
        .not_to be_allowed_globally(:add_project)
    end

    context "with the user being inactive" do
      before do
        user.locked!
      end

      it "still disallows the action globally", :aggregate_failures do
        expect(user)
          .not_to be_allowed_globally(:add_project)

        described_class.execute_as_admin(user) do
          expect(user)
            .not_to be_allowed_globally(:add_project)
        end

        expect(user)
          .not_to be_allowed_globally(:add_project)
      end
    end
  end

  context "with admin privilege elevation required", with_flag: { admin_privilege_elevation: true } do
    shared_let(:admin, reload: true) { create(:admin) }
    shared_let(:other_project) { create(:project) }

    it "elevates the user everywhere for the duration of the block", :aggregate_failures do
      expect(admin.admin_in_project?(project)).to be false

      described_class.execute_as_admin(admin) do
        expect(admin.admin_in_project?(project)).to be true
      end

      expect(admin.admin_in_project?(project)).to be false
    end

    it "restores a previously set elevation", :aggregate_failures do
      admin.admin_elevation = Users::AdminElevation.in_projects([other_project.id])

      described_class.execute_as_admin(admin) do
        expect(admin.admin_in_project?(project)).to be true
      end

      expect(admin.admin_in_project?(project)).to be false
      expect(admin.admin_in_project?(other_project)).to be true
    end

    it "restores the elevation when the block raises" do
      expect do
        described_class.execute_as_admin(admin) { raise ArgumentError }
      end.to raise_error(ArgumentError)

      expect(admin.admin_in_project?(project)).to be false
    end
  end

  it "throws an error if the user is attempted to be saved", :aggregate_failures do
    described_class.execute_as_admin(user) do
      expect { user.save }.to raise_error ActiveRecord::ReadOnlyRecord
      expect { user.save(validate: false) }.to raise_error ActiveRecord::ReadOnlyRecord
      expect { user.update_attribute(:firstname, "Obi") }.to raise_error ActiveRecord::ReadOnlyRecord
    end

    expect(user)
      .not_to be_readonly
  end
end
