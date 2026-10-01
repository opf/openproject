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

require "spec_helper"

RSpec.describe Projects::Exports::QueryExporter do
  shared_let(:permissions) { %i[view_project export_projects] }
  shared_let(:role) { create(:project_role, permissions:) }
  shared_let(:current_user) { create(:user) }

  shared_let(:favorited_project) do
    create(:project, name: "Favorited project", members: { current_user => role })
  end
  shared_let(:other_project) do
    create(:project, name: "Other project", members: { current_user => role })
  end

  before do
    login_as(current_user)
  end

  let(:query) { ProjectQuery.new(user: current_user).select(:name) }
  let(:instance) { described_class.new(query) }

  describe "#all_projects" do
    subject { instance.all_projects.to_a }

    context "without filters" do
      it "returns all projects the user is allowed to export" do
        expect(subject).to contain_exactly(favorited_project, other_project)
      end
    end

    context "with a favorited filter set to true" do
      before do
        create(:favorite, user: current_user, favorited: favorited_project)
        query.where("favored", "=", [OpenProject::Database::DB_VALUE_TRUE])
      end

      it "applies the filter and only returns favorited projects" do
        expect(subject).to contain_exactly(favorited_project)
      end

      context "when the user is not allowed to export one of the favorited projects" do
        shared_let(:second_favorited_project) do
          create(:project, name: "Unauthorized favorite")
        end

        before do
          create(:favorite, user: current_user, favorited: second_favorited_project)
        end

        it "still applies the favorited filter and removes projects missing permission" do
          expect(subject).to contain_exactly(favorited_project)
        end
      end
    end

    context "with a favorited filter set to false" do
      before do
        create(:favorite, user: current_user, favorited: favorited_project)
        query.where("favored", "=", [OpenProject::Database::DB_VALUE_FALSE])
      end

      it "applies the filter and only returns non-favorited projects" do
        expect(subject).to contain_exactly(other_project)
      end
    end

    context "with a name_and_identifier filter" do
      before do
        query.where("name_and_identifier", "=", [favorited_project.name])
      end

      it "applies the filter and only returns matching projects" do
        expect(subject).to contain_exactly(favorited_project)
      end
    end

    context "without export_projects permission" do
      shared_let(:view_only_role) { create(:project_role, permissions: %i[view_project]) }
      shared_let(:view_only_user) do
        create(:user, member_with_roles: { favorited_project => view_only_role,
                                           other_project => view_only_role })
      end

      before do
        login_as(view_only_user)
      end

      let(:query) { ProjectQuery.new(user: view_only_user).select(:name) }

      it "returns no projects" do
        expect(subject).to be_empty
      end
    end

    context "with archived projects" do
      shared_let(:archived_project) do
        create(:project, name: "Archived project", active: false)
      end

      context "as an admin" do
        shared_let(:admin_user) { create(:admin) }

        before do
          login_as(admin_user)
        end

        let(:query) { ProjectQuery.new(user: admin_user).select(:name) }

        it "includes archived projects in the export" do
          expect(subject).to include(archived_project)
        end

        context "with an active filter set to false" do
          before do
            query.where("active", "=", [OpenProject::Database::DB_VALUE_FALSE])
          end

          it "returns only the archived project" do
            expect(subject).to contain_exactly(archived_project)
          end
        end
      end

      context "as a non-admin user" do
        it "does not include archived projects in the export" do
          expect(subject).not_to include(archived_project)
        end
      end
    end
  end
end
