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

RSpec.describe MeetingParticipants::DeleteContract do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:user_with_edit_permissions) do
    create(:user,
           member_with_permissions: { project => %i[view_meetings edit_meetings] })
  end
  shared_let(:user_with_view_only) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:user_not_in_project) { create(:user) }

  let(:participant_user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  let(:participant) { create(:meeting_participant, meeting:, user: participant_user) }
  let(:contract) { described_class.new(participant, user) }

  describe "validation" do
    subject { contract.validate }

    context "when user has edit permissions" do
      let(:user) { user_with_edit_permissions }

      it "is valid" do
        expect(subject).to be true
        expect(contract.errors).to be_empty
      end
    end

    context "when user has only view permission" do
      let(:user) { user_with_view_only }

      it "is invalid" do
        expect(subject).to be false
        expect(contract.errors[:base]).to include("may not be accessed.")
      end
    end

    context "when user is not in project" do
      let(:user) { user_not_in_project }

      it "is invalid" do
        expect(subject).to be false
        expect(contract.errors[:base]).to include("may not be accessed.")
      end
    end
  end
end
