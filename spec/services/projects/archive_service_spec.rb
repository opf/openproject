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

RSpec.describe Projects::ArchiveService do
  let(:project) { create(:project) }
  let(:subproject1) { create(:project) }
  let(:subproject2) { create(:project) }
  let(:subproject3) { create(:project) }
  let(:user) { create(:admin) }
  let(:instance) { described_class.new(user:, model: project) }

  it "sends the notification" do
    allow(OpenProject::Notifications).to receive(:send)

    expect(instance.call).to be_truthy

    expect(OpenProject::Notifications)
      .to(have_received(:send)
            .with(OpenProject::Events::PROJECT_ARCHIVED, project:))
    expect(OpenProject::Notifications)
      .to(have_received(:send)
            .with(OpenProject::Events::PROJECT_ARCHIVED, project:))
  end

  context "with project without any subprojects" do
    it "archives the project" do
      expect(project.reload).not_to be_archived

      expect(instance.call).to be_truthy
      expect(project.reload).to be_archived
    end
  end

  context "with project having subprojects" do
    before do
      project.update(children: [subproject1, subproject2, subproject3])
      project.reload
    end

    shared_examples "when archiving a project" do
      it "archives the project" do
        # Baseline verification.
        expect(project.reload).not_to be_archived

        # Action.
        expect(instance.call).to be_truthy

        # Endline verification.
        expect(project.reload).to be_archived
      end

      it "archives all the subprojects" do
        # Baseline verification.
        expect(subproject1.reload).not_to be_archived
        expect(subproject2.reload).not_to be_archived
        expect(subproject3.reload).not_to be_archived

        # Action.
        expect(instance.call).to be_truthy

        # Endline verification.
        expect(subproject1.reload).to be_archived
        expect(subproject2.reload).to be_archived
        expect(subproject3.reload).to be_archived
      end
    end

    include_examples "when archiving a project"

    context "with deep nesting" do
      before do
        project.update(children: [subproject1])
        subproject1.update(children: [subproject2])
        subproject2.update(children: [subproject3])
        project.reload
        subproject1.reload
      end

      include_examples "when archiving a project"
    end
  end

  context "with project having an archived subproject" do
    let(:subproject1) { create(:project, active: false) }

    before do
      project.update(children: [subproject1, subproject2, subproject3])
      project.reload
    end

    context "while archiving the project" do
      it "does not change timestamp of the already archived subproject" do
        expect(subproject1.reload).to be_archived
        before_timestamp = subproject1.updated_at

        expect(instance.call).to be_truthy

        after_timestamp = subproject1.reload.updated_at
        expect(before_timestamp).to eq(after_timestamp)
      end

      it "changes timestamp of the active subproject" do
        expect(subproject2.reload).not_to be_archived
        before_timestamp = subproject2.updated_at

        expect(instance.call).to be_truthy

        after_timestamp = subproject2.reload.updated_at
        expect(before_timestamp).not_to eq(after_timestamp)
      end
    end
  end

  context "with the seeded demo project" do
    let(:demo_project) { create(:project, name: "Demo project", identifier: "demo-project", public: true) }
    let(:instance) { described_class.new(user:, model: demo_project) }

    it "saves in a Setting that the demo project was modified (regression #52826)" do
      # Archive the demo project
      expect(instance.call).to be_truthy
      expect(demo_project.reload).to be_archived

      # Demo project is not available any more for the onboarding tour
      expect(Setting.demo_projects_available).to be(false)
    end
  end
end
