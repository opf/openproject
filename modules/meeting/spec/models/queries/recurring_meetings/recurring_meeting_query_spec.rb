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

RSpec.describe Queries::RecurringMeetings::RecurringMeetingQuery do
  subject { described_class.new(user:) }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let(:visible_project) do
    create(:project, members: { user => create(:project_role, permissions: %i[view_meetings]) })
  end
  let!(:visible_series_a) do
    create(:recurring_meeting, project: visible_project, author: user,
                               start_time: 1.day.from_now, created_at: 2.days.ago)
  end
  let!(:visible_series_b) do
    create(:recurring_meeting, project: visible_project, author: other_user,
                               start_time: 2.days.from_now, created_at: 1.day.ago)
  end

  let(:invisible_project) { create(:project) }
  let!(:invisible_series) { create(:recurring_meeting, project: invisible_project) }

  context "without a filter" do
    it "returns all visible recurring meetings" do
      expect(subject.results).to contain_exactly(visible_series_a, visible_series_b)
    end

    it "does not return recurring meetings from projects without permission" do
      expect(subject.results).not_to include(invisible_series)
    end
  end

  context "when filtering by project" do
    let(:other_visible_project) do
      create(:project, members: { user => create(:project_role, permissions: %i[view_meetings]) })
    end
    let!(:other_visible_series) { create(:recurring_meeting, project: other_visible_project, author: user) }

    before { subject.where("project_id", "=", [other_visible_project.id]) }

    it "returns only visible recurring meetings for that project" do
      expect(subject.results).to contain_exactly(other_visible_series)
    end
  end

  context "when filtering by author" do
    before { subject.where("author_id", "=", [other_user.id]) }

    it "returns only recurring meetings created by that author" do
      expect(subject.results).to contain_exactly(visible_series_b)
    end
  end

  context "when sorting by start_time ascending" do
    before { subject.order(start_time: :asc) }

    it "returns results ordered by start_time asc" do
      expect(subject.results.to_a).to eq([visible_series_a, visible_series_b])
    end
  end

  context "when sorting by start_time descending" do
    before { subject.order(start_time: :desc) }

    it "returns results ordered by start_time desc" do
      expect(subject.results.to_a).to eq([visible_series_b, visible_series_a])
    end
  end

  context "when sorting by created_at ascending" do
    before { subject.order(created_at: :asc) }

    it "returns results ordered by created_at asc" do
      expect(subject.results.to_a).to eq([visible_series_a, visible_series_b])
    end
  end
end
