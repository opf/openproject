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

RSpec.describe Query::Results, "Project filter integration" do
  let(:query) do
    build(:query,
          user:,
          project: parent_project).tap do |q|
      q.filters.clear
    end
  end
  let(:query_results) do
    described_class.new query
  end

  shared_let(:parent_project) { create(:project) }
  shared_let(:child_project) { create(:project, parent: parent_project) }

  shared_let(:second_parent_project) { create(:project) }
  shared_let(:second_child_project) { create(:project, parent: second_parent_project) }

  shared_let(:user) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_permissions: {
             parent_project => [:view_work_packages],
             child_project => [:view_work_packages],
             second_parent_project => [:view_work_packages],
             second_child_project => [:view_work_packages]
           })
  end

  shared_let(:parent_wp) { create(:work_package, project: parent_project) }
  shared_let(:child_wp) { create(:work_package, project: child_project) }

  shared_let(:second_parent_wp) { create(:work_package, project: second_parent_project) }
  shared_let(:second_child_wp) { create(:work_package, project: second_child_project) }

  before do
    login_as user
  end

  describe "both parent projects selected" do
    before do
      query.add_filter "project_id", "=", [parent_project.id, second_parent_project.id]
    end

    context "when subprojects included", with_settings: { display_subprojects_work_packages: true } do
      it "shows the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(parent_wp, child_wp, second_parent_wp, second_child_wp)
      end
    end

    context "when subprojects not included", with_settings: { display_subprojects_work_packages: false } do
      it "does not show the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(parent_wp, second_parent_wp)
      end
    end

    context "when subprojects explicitly disabled" do
      before do
        query.include_subprojects = false
      end

      it "does not show the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(parent_wp, second_parent_wp)
      end
    end
  end

  describe "one parent projects selected" do
    before do
      query.add_filter "project_id", "=", [second_parent_project.id]
    end

    context "when subprojects included", with_settings: { display_subprojects_work_packages: true } do
      it "shows the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(second_parent_wp, second_child_wp)
      end
    end

    context "when subprojects not included", with_settings: { display_subprojects_work_packages: false } do
      it "does not show the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(second_parent_wp)
      end
    end

    context "when subprojects explicitly disabled" do
      before do
        query.include_subprojects = false
      end

      it "does not show the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(second_parent_wp)
      end
    end
  end

  describe "one parent and one other child selected" do
    before do
      query.add_filter "project_id", "=", [child_project.id, second_parent_project.id]
    end

    context "when subprojects included", with_settings: { display_subprojects_work_packages: true } do
      it "shows the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(child_wp, second_parent_wp, second_child_wp)
      end
    end

    context "when subprojects not included", with_settings: { display_subprojects_work_packages: false } do
      it "does not show the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(child_wp, second_parent_wp)
      end
    end

    context "when subprojects explicitly disabled" do
      before do
        query.include_subprojects = false
      end

      it "does not show the sub work packages" do
        expect(query_results.work_packages).to contain_exactly(child_wp, second_parent_wp)
      end
    end
  end
end
