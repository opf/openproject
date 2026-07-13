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

RSpec.describe Projects::CopyService, "integration", type: :model do
  shared_let(:role) do
    create(:project_role,
           permissions: %i[copy_projects])
  end
  shared_let(:source) do
    create(:project,
           name: "Source Project Name",
           enabled_module_names: %i[work_package_tracking backlogs])
  end
  shared_let(:current_user) do
    create(:user,
           member_with_roles: { source => role })
  end

  let(:instance) { described_class.new(source:, user: current_user) }
  let(:target_project_params) do
    { name: "Target Project Name", identifier: "some-identifier" }
  end
  let(:params) do
    { target_project_params:, send_notifications: false }
  end
  let(:project_copy) { subject.result }

  describe ".call" do
    subject { instance.call(params) }

    describe "#sprint_sharing setting" do
      context "with an ee license for sprint sharing", with_ee: %i[sprint_sharing] do
        context "when the source project is set to receive" do
          before do
            source.sprint_sharing = Projects::SprintSharing::RECEIVE_SHARED
            source.save!
          end

          it "copies the backlog sharing setting" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSharing::RECEIVE_SHARED
          end
        end

        context "when the source project is set to share with subprojects" do
          before do
            source.sprint_sharing = Projects::SprintSharing::SHARE_SUBPROJECTS
            source.save!
          end

          it "copies the backlog sharing setting" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSharing::SHARE_SUBPROJECTS
          end
        end

        context "when the source project is set to not share" do
          before do
            source.sprint_sharing = Projects::SprintSharing::NO_SHARING
            source.save!
          end

          it "copies the backlog sharing setting" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSharing::NO_SHARING
          end
        end

        context "when the source project is set to share with all" do
          before do
            source.sprint_sharing = Projects::SprintSharing::SHARE_ALL_PROJECTS
            source.save!
          end

          it "does not copy the setting as that would result in two projects sharing with all" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSharing::NO_SHARING
          end
        end
      end

      context "without an ee license for sprint sharing", with_ee: %i[] do
        Projects::SprintSharing::SPRINT_SHARING_MODES.each do |mode|
          context "when the source project is set to #{mode}" do
            before do
              source.sprint_sharing = mode
              source.save!
            end

            it "copies the backlog sharing setting" do
              expect(subject).to be_success
              expect(project_copy.sprint_sharing).to eq Projects::SprintSharing::NO_SHARING
            end
          end
        end
      end
    end
  end
end
