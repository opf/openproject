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

require_relative "../spec_helper"

RSpec.describe MeetingParticipant do
  subject { build(:meeting_participant) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a user" do
      subject.user = nil
      expect(subject).not_to be_valid
    end

    it "is not valid without a meeting" do
      subject.meeting = nil
      expect(subject).not_to be_valid
    end
  end

  describe "#name" do
    it "returns the user's name if user is present" do
      expect(subject.name).to eq(subject.user.name)
    end

    it "returns 'user.deleted' if user is nil" do
      subject.user = nil
      expect(subject.name).to eq(I18n.t("user.deleted"))
    end
  end

  describe "#mail" do
    it "returns the user's mail if user is present" do
      expect(subject.mail).to eq(subject.user.mail)
    end

    it "returns 'user.deleted' if user is nil" do
      subject.user = nil
      expect(subject.mail).to eq(I18n.t("user.deleted"))
    end
  end

  describe "#status_sorting_value" do
    it "returns correct sorting value for 'accepted' status" do
      subject.participation_status = "accepted"
      expect(subject.status_sorting_value).to eq(1)
    end

    it "returns correct sorting value for 'tentative' status" do
      subject.participation_status = "tentative"
      expect(subject.status_sorting_value).to eq(2)
    end

    it "returns correct sorting value for 'declined' status" do
      subject.participation_status = "declined"
      expect(subject.status_sorting_value).to eq(3)
    end

    it "returns correct sorting value for 'needs-action' status" do
      subject.participation_status = "needs-action"
      expect(subject.status_sorting_value).to eq(4)
    end

    it "returns correct sorting value for 'unknown' status" do
      subject.participation_status = "unknown"
      expect(subject.status_sorting_value).to eq(4)
    end
  end

  describe "#copy_attributes" do
    it "excludes attributes we do not want to copy" do
      attributes = subject.copy_attributes
      expect(attributes.keys).not_to include(
        "id",
        "created_at",
        "updated_at",
        "meeting_id",
        "attended",
        "comment"
      )
    end
  end
end
