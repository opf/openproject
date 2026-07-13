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

require "spec_helper"

RSpec.describe OpenProject::Notifications, "backlogs event subscriptions" do # rubocop:disable RSpec/SpecFilePathFormat
  describe "MODULE_DISABLED" do
    subject do
      described_class.send(
        OpenProject::Events::MODULE_DISABLED,
        disabled_module:
      )
    end

    Projects::SprintSharing::SPRINT_SHARING_MODES.each do |sharing_mode|
      context "when the backlogs module is disabled on a project with #{sharing_mode}" do
        let(:project) { create(:project, sprint_sharing: sharing_mode) }
        let(:disabled_module) { instance_double(EnabledModule, name: "backlogs", project:) }

        it "sets sprint sharing to no_sharing" do
          subject

          expect(project.reload.sprint_sharing).to eq(Projects::SprintSharing::NO_SHARING)
        end
      end
    end

    context "when a different module is disabled" do
      let(:project) do
        create(:project, sprint_sharing: Projects::SprintSharing::SHARE_ALL_PROJECTS)
      end
      let(:disabled_module) { instance_double(EnabledModule, name: "wiki", project:) }

      it "does not reset sprint sharing" do
        subject

        expect(project.reload.sprint_sharing).to eq(Projects::SprintSharing::SHARE_ALL_PROJECTS)
      end
    end
  end

  describe "PROJECT_ARCHIVED" do
    subject do
      described_class.send(
        OpenProject::Events::PROJECT_ARCHIVED,
        project:
      )
    end

    Projects::SprintSharing::SPRINT_SHARING_MODES.each do |sharing_mode|
      context "when a project with #{sharing_mode} is archived" do
        let(:project) { create(:project, sprint_sharing: sharing_mode) }

        it "sets sprint sharing to no_sharing" do
          subject

          expect(project.reload.sprint_sharing).to eq(Projects::SprintSharing::NO_SHARING)
        end
      end
    end
  end
end
