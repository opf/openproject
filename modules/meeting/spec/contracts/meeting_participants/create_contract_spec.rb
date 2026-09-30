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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe MeetingParticipants::CreateContract do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:user_with_meeting_permissions) do
    create(:user,
           member_with_permissions: { project => %i[view_meetings edit_meetings] })
  end
  shared_let(:user_without_meeting_permissions) { create(:user, member_with_permissions: { project => %i[view_project] }) }
  shared_let(:user_not_in_project) { create(:user) }

  let(:participant) { build(:meeting_participant, :needs_action, meeting:, user:) }
  let(:contract) { described_class.new(participant, user) }

  describe "validation" do
    subject { contract.validate }

    context "when all attributes are valid" do
      let(:user) { user_with_meeting_permissions }

      it "is valid" do
        expect(subject).to be true
        expect(contract.errors).to be_empty
      end
    end

    context "when meeting is missing" do
      let(:user) { user_with_meeting_permissions }
      let(:participant) { build(:meeting_participant, meeting: nil, user:) }

      it "is invalid" do
        expect(subject).to be false
        expect(contract.errors[:meeting]).to include("can't be blank.")
      end
    end

    context "when user does not have meeting permissions" do
      let(:user) { user_without_meeting_permissions }

      it "is invalid" do
        expect(subject).to be false
        expect(contract.errors[:user]).to include("is not a valid participant.")
        expect(contract.errors[:base]).not_to include(user_without_meeting_permissions.name)
      end
    end

    context "when user is not in project" do
      let(:user) { user_not_in_project }

      it "is invalid" do
        expect(subject).to be false
        expect(contract.errors[:user]).to include("is not a valid participant.")
        expect(contract.errors[:base]).not_to include(user_not_in_project.name)
      end
    end
  end
end
