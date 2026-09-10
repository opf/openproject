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

RSpec.describe Queries::Meetings::Filters::TitleFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :text }
    let(:class_key) { :title }
    let(:human_name) { "Title" }

    describe "#available?" do
      it "is true" do
        expect(instance).to be_available
      end
    end

    describe "#allowed_values" do
      it "is nil" do
        expect(instance.allowed_values).to be_nil
      end
    end

    it_behaves_like "non ar filter"
  end

  describe "#apply_to" do
    let(:project) { create(:project) }
    let!(:matching_meeting) { create(:meeting, project:, title: "UX Design Daily") }
    let!(:other_meeting) { create(:meeting, project:, title: "Backend Weekly") }

    let(:series) { create(:recurring_meeting, project:, title: "UX Research Sync") }
    let!(:occurrence) do
      create(:recurring_meeting_occurrence,
             recurring_meeting: series,
             title: "Renamed occurrence",
             start_time: 1.week.from_now)
    end

    let(:instance) { described_class.create!(name: :title, operator:, values:) }

    subject { instance.apply_to(Meeting.not_templated).pluck(:id) }

    context 'for "~"' do
      let(:operator) { "~" }
      let(:values) { ["ux"] }

      it "matches meeting titles case-insensitively and partially" do
        expect(subject).to contain_exactly(matching_meeting.id, occurrence.id)
      end
    end

    context 'for "~" with a term only present in the series title' do
      let(:operator) { "~" }
      let(:values) { ["research"] }

      it "matches the occurrence through its series" do
        expect(subject).to contain_exactly(occurrence.id)
      end
    end

    context 'for "~" with multiple tokens' do
      let(:operator) { "~" }
      let(:values) { ["design ux"] }

      it "requires all tokens to be contained in one of the titles" do
        expect(subject).to contain_exactly(matching_meeting.id)
      end
    end

    context 'for "!~"' do
      let(:operator) { "!~" }
      let(:values) { ["ux"] }

      it "excludes meetings matching on their own or their series title" do
        expect(subject).to contain_exactly(other_meeting.id)
      end
    end
  end
end
