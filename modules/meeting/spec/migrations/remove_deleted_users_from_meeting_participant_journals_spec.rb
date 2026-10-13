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
require Rails.root.join(
  "modules/meeting/db/migrate/20261010070000_remove_deleted_users_from_meeting_participant_journals.rb"
)

RSpec.describe RemoveDeletedUsersFromMeetingParticipantJournals, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  shared_let(:remaining_user) { create(:user) }
  shared_let(:removed_user) { create(:user) }
  shared_let(:meeting) { create(:meeting) }

  before do
    create(:meeting_participant, meeting:, user: remaining_user)
    create(:meeting_participant, meeting:, user: removed_user)
    meeting.save_journals

    # Simulates a user deleted before deleting users removed their participant journals.
    Journal::MeetingParticipantJournal.where(user_id: removed_user.id).update_all(user_id: User.maximum(:id) + 1)
  end

  it "removes the participant journals of users that no longer exist" do
    migrate

    expect(Journal::MeetingParticipantJournal.where(journal: meeting.journals).pluck(:user_id))
      .to contain_exactly(remaining_user.id)
  end
end
