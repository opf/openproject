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

require "rails_helper"

RSpec.describe WorkPackages::BulkDeleteDialogComponent, type: :component do
  let(:user) { create(:admin) }

  let(:main_project) { create(:project, name: "Main Project") }
  let(:sub_project) { create(:project, name: "Sub Project", parent: main_project) }
  let(:sub_sub_project) { create(:project, name: "Sub Sub Project", parent: sub_project) }

  let(:wp_main) { create(:work_package, project: main_project) }
  let(:work_packages) { [wp_main] }

  subject(:component) { described_class.new(work_packages:) }

  before do
    User.current = user
  end

  describe "#projects" do
    context "when all work packages belong to the same project and have no descendants" do
      it "returns only that project" do
        expect(component.send(:projects)).to eq([main_project])
      end
    end

    context "when work packages have descendants in sub-projects" do
      let(:child_wp) { create(:work_package, project: sub_project, parent: wp_main) }
      let(:grandchild_wp) { create(:work_package, project: sub_sub_project, parent: child_wp) }

      before do
        grandchild_wp # ensure all records are created
      end

      it "includes projects from descendants" do
        projects = component.send(:projects)

        expect(projects).to include(main_project, sub_project, sub_sub_project)
      end

      it "reports multiple projects" do
        expect(component.send(:multiple_projects?)).to be true
      end

      it "lists all project names" do
        expect(component.send(:project_names)).to include("Main Project", "Sub Project", "Sub Sub Project")
      end
    end
  end

  describe "#description" do
    context "when work packages have no descendants" do
      it "returns the description without children mention" do
        expect(component.send(:description)).to eq(
          "The following work packages and all associated data will be permanently deleted:"
        )
      end
    end

    context "when work packages have descendants" do
      let(:child_wp) { create(:work_package, project: main_project, parent: wp_main) }

      before do
        child_wp # ensure record is created
      end

      it "returns the description mentioning children" do
        expect(component.send(:description)).to eq(
          "The following work packages, including children and all associated data, will be permanently deleted:"
        )
      end
    end
  end
end
