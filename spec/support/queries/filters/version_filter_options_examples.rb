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

RSpec.shared_examples_for "version filter options" do
  let(:parent_project) { create(:project, name: "Borealis", public: false) }
  let(:filter_project) { create(:project, name: "Aurora", public: false, parent: parent_project) }
  let(:allowed_values_user) do
    create(:user,
           member_with_roles: { filter_project => create(:project_role, permissions: %i[view_work_packages]) })
  end

  let!(:charlie) { create(:version, name: "Charlie", project: filter_project) }
  let!(:alpha) { create(:version, name: "Alpha", project: filter_project) }
  let!(:bravo) { create(:version, name: "Bravo", project: parent_project, sharing: "descendants") }
  let!(:inaccessible) { create(:version, name: "Delta", project: create(:project, public: false)) }

  let(:values) { [] }

  before { login_as(allowed_values_user) }

  describe "#allowed_values" do
    context "within a project" do
      let(:project) { filter_project }

      it "labels local and shared versions with their name, ordered by project then name" do
        expect(instance.allowed_values)
          .to eq([["Alpha", alpha.id.to_s], ["Charlie", charlie.id.to_s], ["Bravo", bravo.id.to_s]])
      end
    end

    context "without a project" do
      let(:project) { nil }

      it "labels the versions visible to the user with their name, ordered by project then name" do
        expect(instance.allowed_values)
          .to eq([["Alpha", alpha.id.to_s], ["Charlie", charlie.id.to_s]])
      end
    end
  end

  describe "#autocomplete_options" do
    context "within a project" do
      let(:project) { filter_project }

      it "groups local and shared versions by project name" do
        expect(instance.autocomplete_options).to include(
          component: "opce-autocompleter",
          groupBy: "project_name",
          bindLabel: "name",
          bindValue: "id",
          items: [
            { name: "Alpha", id: alpha.id.to_s, project_name: "Aurora" },
            { name: "Charlie", id: charlie.id.to_s, project_name: "Aurora" },
            { name: "Bravo", id: bravo.id.to_s, project_name: "Borealis" }
          ]
        )
      end

      it "preselects nothing without values" do
        expect(instance.autocomplete_options[:model]).to be_empty
      end

      context "with a selected version" do
        let(:values) { [alpha.id.to_s] }

        it "preselects the item matching the value" do
          expect(instance.autocomplete_options[:model])
            .to eq([{ name: "Alpha", id: alpha.id.to_s, project_name: "Aurora" }])
        end
      end
    end

    context "without a project" do
      let(:project) { nil }

      it "groups the versions visible to the user by project name" do
        expect(instance.autocomplete_options).to include(
          groupBy: "project_name",
          items: [
            { name: "Alpha", id: alpha.id.to_s, project_name: "Aurora" },
            { name: "Charlie", id: charlie.id.to_s, project_name: "Aurora" }
          ]
        )
      end
    end
  end
end
