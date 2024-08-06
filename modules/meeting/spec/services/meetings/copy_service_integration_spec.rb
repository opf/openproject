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

RSpec.describe Meetings::CopyService, "integration", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i(view_meetings create_meetings) })
  end
  shared_let(:meeting) { create(:structured_meeting, project:, start_time: Time.parse("2013-03-27T15:35:00Z")) }

  let(:instance) { described_class.new(model: meeting, user:) }
  let(:attributes) { {} }
  let(:params) { {} }

  let(:service_result) { instance.call(attributes:, **params) }
  let(:copy) { service_result.result }

  it "copies the meeting as is" do
    expect(service_result).to be_success
    expect(copy.author).to eq(user)
    expect(copy.start_time).to eq(meeting.start_time + 1.week)
  end

  context "when the meeting is closed" do
    it "reopens the meeting" do
      meeting.update! state: "closed"
      expect(service_result).to be_success
      expect(copy.state).to eq("open")
    end
  end

  describe "with participants" do
    let(:invited_user) { create(:user, member_with_permissions: { project => %i(view_meetings) }) }
    let(:attending_user) { create(:user, member_with_permissions: { project => %i(view_meetings) }) }
    let(:invalid_user) { create(:user) }

    it "copies applicable participants, resetting attended status" do
      meeting.participants.create!(user: invited_user, invited: true, attended: false)
      meeting.participants.create!(user: attending_user, invited: true, attended: true)
      meeting.participants.create!(user: invalid_user, invited: true, attended: true)

      expect(service_result).to be_success
      expect(copy.participants.count).to eq(2)
      invited = copy.participants.find_by(user: invited_user)
      attending = copy.participants.find_by(user: attending_user)
      expect(invited).to be_invited
      expect(invited).not_to be_attended

      expect(attending).to be_invited
      expect(attending).not_to be_attended

      invalid = copy.participants.find_by(user: invalid_user)
      expect(invalid).to be_nil
    end
  end

  describe "without participants" do
    it "sets the author as invited" do
      meeting.participants.destroy_all

      expect(service_result).to be_success
      expect(copy.participants.count).to eq(1)
      invited = copy.participants.find_by(user:)
      expect(invited).to be_invited
    end
  end

  describe "when not saving" do
    let(:params) { { save: false } }

    it "builds the meeting" do
      expect(service_result).to be_success
      expect(copy.author).to eq(user)
      expect(copy.start_time).to eq(meeting.start_time + 1.week)
      expect(copy).to be_new_record
    end
  end

  context "with agenda items" do
    shared_let(:agenda_item) do
      create(:meeting_agenda_item,
             meeting:,
             notes: "hello there")
    end

    it "copies the agenda item" do
      expect(copy.reload.agenda_items.length)
        .to eq 1

      expect(copy.agenda_items.first.notes)
        .to eq agenda_item.notes
    end

    context "when asking not to copy agenda" do
      let(:params) { { copy_agenda: false } }

      it "does not copy agenda items" do
        expect(copy.agenda_items).to be_empty
      end
    end
  end

  context "with attachments" do
    shared_let(:attachment) do
      create(:attachment,
             container: meeting)
    end
    shared_let(:agenda_item) do
      create(:meeting_agenda_item,
             meeting:,
             notes: "![](/api/v3/attachments/#{attachment.id}/content")
    end

    context "when asking to copy attachments" do
      let(:params) { { copy_attachments: true } }

      it "copies the attachment" do
        expect(copy.attachments.length)
          .to eq 1

        expect(copy.attachments.first.id)
          .not_to eq attachment.id

        expect(copy.agenda_items.count).to eq(1)
        expect(copy.agenda_items.first.notes).to include "attachments/#{copy.attachments.first.id}/content"
      end
    end

    context "when asking not to copy attachments" do
      let(:params) { { copy_attachments: false } }

      it "does not copy attachments" do
        expect(copy.attachments).to be_empty
        expect(copy.agenda_items.first.notes).to include "attachments/#{attachment.id}/content"
      end
    end
  end
end
