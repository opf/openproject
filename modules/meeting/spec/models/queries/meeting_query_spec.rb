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

RSpec.describe Queries::Meetings::MeetingQuery do
  subject { described_class.new(user:) }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let(:visible_project) { create(:project, members: { user => create(:project_role, permissions: %i[view_meetings]) }) }
  let!(:visible_meeting_past) { create(:meeting, project: visible_project, author: user, start_time: 1.day.ago) }
  let!(:visible_meeting_ongoing) do
    # meeting started 20 minutes ago and goes on for 2 hours, so it's still ongoing now and should be included
    # in future scopes
    create(:meeting, project: visible_project, author: user, start_time: 20.minutes.ago, duration: 2)
  end
  let!(:visible_meeting_future) { create(:meeting, project: visible_project, author: user, start_time: 1.day.from_now) }

  let(:invisible_project) { create(:project) }
  let!(:invisible_meeting) { create(:meeting, project: invisible_project, start_time: 1.day.ago) }

  context "without a filter" do
    it "returns all visible meetings" do
      expect(subject.results).to contain_exactly(visible_meeting_past, visible_meeting_ongoing, visible_meeting_future)
    end
  end

  context "when filtering by project" do
    let(:other_visible_project) { create(:project, members: { user => create(:project_role, permissions: %i[view_meetings]) }) }
    let!(:other_visible_meeting) { create(:meeting, project: other_visible_project, author: user, start_time: 1.day.ago) }

    before do
      subject.where("project_id", "=", [other_visible_project.id])
    end

    it "returns only visible meetings for that project" do
      expect(subject.results).to contain_exactly(other_visible_meeting)
    end
  end

  context "when filtering by time" do
    context "for future meetings" do
      before do
        subject.where("time", "=", ["future"])
      end

      it "returns meetings starting in the future and meetings currently ongoing" do
        expect(subject.results).to contain_exactly(visible_meeting_future, visible_meeting_ongoing)
      end
    end

    context "for past meetings" do
      before do
        subject.where("time", "=", ["past"])
      end

      it "returns meetings starting in the past and meetings currently ongoing" do
        expect(subject.results).to contain_exactly(visible_meeting_past, visible_meeting_ongoing)
      end
    end
  end

  context "when filtering by attending users" do
    before do
      create(:meeting_participant, user: other_user, meeting: visible_meeting_ongoing, attended: true)
      create(:meeting_participant, user: other_user, meeting: visible_meeting_future, attended: false)
      subject.where("attended_user_id", "=", [other_user.id])
    end

    it "returns meetings where the given user is attending" do
      expect(subject.results).to contain_exactly(visible_meeting_ongoing)
    end
  end

  context "when filtering by invited users" do
    before do
      create(:meeting_participant, user: other_user, meeting: visible_meeting_ongoing, invited: true)
      create(:meeting_participant, user: other_user, meeting: visible_meeting_future, invited: false)
      subject.where("invited_user_id", "=", [other_user.id])
    end

    it "returns meetings where the given user is invited" do
      expect(subject.results).to contain_exactly(visible_meeting_ongoing)
    end
  end

  context "when filtering by author" do
    before do
      visible_meeting_future.update(author: other_user)
      subject.where("author_id", "=", [other_user.id])
    end

    it "returns meetings where the given user is invited" do
      expect(subject.results).to contain_exactly(visible_meeting_future)
    end
  end
end
