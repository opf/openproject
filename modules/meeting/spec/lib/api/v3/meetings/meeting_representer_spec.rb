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

RSpec.describe API::V3::Meetings::MeetingRepresenter do
  include API::V3::Utilities::PathHelper

  let(:workspace) { build_stubbed(:project) }
  let(:current_user) do
    build_stubbed(:user)
  end
  let(:meeting) do
    build_stubbed(:meeting,
                  author: current_user,
                  location: "https://foo.example.com",
                  project: workspace)
  end

  let(:embed_links) { true }
  let(:representer) { described_class.new(meeting, current_user:, embed_links:) }

  describe "generation" do
    subject(:generated) { representer.to_json }

    it "fulfills the documented schema" do
      expect(generated).to match_json_schema.from_docs("meeting_model")
    end

    describe "self link" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.meeting(meeting.id) }
        let(:title) { meeting.title }
      end
    end

    it_behaves_like "has an untitled link" do
      let(:link) { :attachments }
      let(:href) { api_v3_paths.attachments_by_meeting meeting.id }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "author" }
      let(:href) { api_v3_paths.user(current_user.id) }
      let(:title) { current_user.name }
    end

    it_behaves_like "has workspace linked"
    it_behaves_like "has workspace embedded"

    it_behaves_like "has an untitled action link" do
      let(:link) { :addAttachment }
      let(:href) { api_v3_paths.attachments_by_meeting meeting.id }
      let(:method) { :post }
      let(:permission) { :edit_meetings }
    end

    it "describes the object", :aggregate_failures do
      expect(subject).to be_json_eql("Meeting".to_json).at_path("_type")
      expect(subject).to be_json_eql(meeting.id.to_json).at_path("id")
      expect(subject).to be_json_eql(meeting.title.to_json).at_path("title")
      expect(subject).to be_json_eql(meeting.lock_version.to_json).at_path("lockVersion")
      expect(subject).to be_json_eql(meeting.start_time.utc.iso8601(3).to_json).at_path("startTime")
      expect(subject).to be_json_eql(meeting.end_time.utc.iso8601(3).to_json).at_path("endTime")
      expect(subject).to be_json_eql("PT1H".to_json).at_path("duration")
      expect(subject).to be_json_eql(meeting.location.to_json).at_path("location")

      expect(subject).to be_json_eql(meeting.created_at.utc.iso8601(3).to_json).at_path("createdAt")
      expect(subject).to be_json_eql(meeting.updated_at.utc.iso8601(3).to_json).at_path("updatedAt")
    end
  end

  describe "notify" do
    subject(:generated) { representer.to_json }

    it "reflects the resolved notify status (notify?) rather than the raw column" do
      allow(meeting).to receive_messages(notify?: true, notify: false)

      expect(generated).to be_json_eql(true.to_json).at_path("notify")
    end
  end
end
