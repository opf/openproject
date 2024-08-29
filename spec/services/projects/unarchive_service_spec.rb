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

RSpec.describe Projects::UnarchiveService do
  let(:project) { create(:project, active: false) }
  let(:user) { create(:admin) }
  let(:instance) { described_class.new(user:, model: project) }

  it "unarchives and sends the notification" do
    allow(OpenProject::Notifications).to receive(:send)
    expect(project.active).to be(false)

    expect(instance.call).to be_truthy

    expect(project.active).to be(true)
    expect(OpenProject::Notifications)
      .to(have_received(:send)
            .with(OpenProject::Events::PROJECT_UNARCHIVED, project:))
    expect(OpenProject::Notifications)
      .to(have_received(:send)
            .with(OpenProject::Events::PROJECT_UNARCHIVED, project:))
  end

  context "with the seeded demo project" do
    let(:demo_project) do
      create(:project, name: "Demo project", identifier: "demo-project", public: true, active: false)
    end
    let(:instance) { described_class.new(user:, model: demo_project) }

    it "saves in a Setting that the demo project was modified (regression #52826)" do
      # Un-archive the demo project
      expect(instance.call).to be_truthy
      expect(demo_project.active).to be(true)

      # Demo project is available for the onboarding tour again
      expect(Setting.demo_projects_available).to be(true)
    end
  end
end
