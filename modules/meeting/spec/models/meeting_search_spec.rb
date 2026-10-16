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

RSpec.describe Meeting, "search" do
  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_meetings]) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  let(:meeting) { create(:meeting, project:, title: "Weekly sync") }
  let!(:section) { create(:meeting_section, meeting:, title: "Budget planning") }
  let!(:agenda_item) { create(:meeting_agenda_item, meeting:, title: "Roadmap review", notes: "discuss milestones") }

  describe ".search" do
    it "finds a meeting by its section title" do
      login_as(user)
      results, = described_class.search("Budget", nil)

      expect(results).to include(meeting)
    end
  end

  describe "#searchable_content" do
    it "returns only the matching agenda item for a content match" do
      snippet = meeting.searchable_content(%w[roadmap])

      expect(snippet).to include("Roadmap review", "discuss milestones")
      expect(snippet).not_to include("Budget planning")
    end

    it "returns the section title for a section match" do
      expect(meeting.searchable_content(%w[budget])).to eq("Budget planning")
    end

    it "is blank for a match on the meeting title only" do
      expect(meeting.searchable_content(%w[weekly])).to eq("")
    end
  end
end
