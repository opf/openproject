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

RSpec.describe Principals::DeleteJob, type: :model do
  subject(:job) { described_class.perform_now(principal) }

  shared_let(:deleted_user) { create(:deleted_user) }
  shared_let(:principal) { create(:user) }
  shared_let(:other_user) { create(:user) }
  shared_let(:meeting) { create(:meeting) }

  before do
    create(:meeting_participant, meeting:, user: principal, invited: true)
    create(:meeting_participant, meeting:, user: other_user, invited: true)
    meeting.save_journals
  end

  it "removes the user from the participant history of the meeting" do
    job

    expect(Journal::MeetingParticipantJournal.where(journal: meeting.journals).pluck(:user_id))
      .to contain_exactly(other_user.id)
  end

  it "leaves the latest journal in sync with the meeting" do
    job

    expect { meeting.reload.save_journals }.not_to change(Journal, :count)
  end
end
