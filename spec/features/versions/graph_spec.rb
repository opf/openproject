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

RSpec.describe "version show graph", :js do
  shared_let(:user) { create(:admin) }
  # parent
  # +- sibling
  # +- main   <- version created here
  #    +- child
  # other
  shared_let(:parent_project) { create(:project, name: "parent") }
  shared_let(:sibling_project) { create(:project, parent: parent_project, name: "sibling") }
  shared_let(:main_project) { create(:project, parent: parent_project, name: "main") }
  shared_let(:child_project) { create(:project, parent: main_project, name: "child") }
  shared_let(:other_project) { create(:project, name: "other") }
  shared_let(:version) { create(:version, project: main_project) }

  # as assertions against the graph can't be made, we use different statuses and
  # test the graph labels to ensure the work packages are drawn in the graph.
  shared_let(:status_control) { create(:status, name: "Control") }
  shared_let(:status_sut) { create(:status, name: "Subject under test") }

  # This one exists to have at least one work package in the graph
  shared_let(:control_wp) do
    create(:work_package,
           project: main_project,
           status: status_control,
           version:)
  end

  current_user { user }

  def expect_work_packages_visible_in_graph
    expect(page).to have_css(".work-packages-embedded-view--container", wait: 20)
    expect(page).to have_css(".op-wp-embedded-graph", visible: :all, wait: 20)
    canvas = find(".op-wp-embedded-graph canvas")
    expect(canvas.text).to eq("1 Control; 1 Subject under test")
  end

  context "for a version not shared" do
    before do
      version.update(sharing: "none")
    end

    it "can show a work package from the same project" do
      create(:work_package,
             project: main_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end
  end

  context "for a version shared with all projects" do
    before do
      version.update(sharing: "system")
    end

    it "can show a work package from a different project" do
      create(:work_package,
             project: other_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end
  end

  context "for a version shared with subprojects" do
    before do
      version.update(sharing: "descendants")
    end

    it "can show a work package from a descendant project" do
      create(:work_package,
             project: child_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end
  end

  context "for a version shared with hierarchy" do
    before do
      version.update(sharing: "hierarchy")
    end

    it "can show a work package from a descendant project" do
      create(:work_package,
             project: child_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end

    it "can show a work package from an ancestor project" do
      create(:work_package,
             project: parent_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end
  end

  context "for a version shared with tree" do
    before do
      version.update(sharing: "tree")
    end

    it "can show a work package from a descendant project" do
      create(:work_package,
             project: child_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end

    it "can show a work package from an ancestor project" do
      create(:work_package,
             project: parent_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end

    it "can show a work package from a sibling project" do
      create(:work_package,
             project: sibling_project,
             status: status_sut,
             version:)

      visit version_path(version)
      expect_work_packages_visible_in_graph
    end
  end
end
