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

RSpec.describe Queries::Meetings::Filters::StateFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :state }
    let(:human_name) { "Meeting status" }

    describe "#allowed_values" do
      it "offers the statuses a meeting moves through, in lifecycle order" do
        expect(instance.allowed_values)
          .to eq([["Draft", 1], ["Open", 0], ["In progress", 3], ["Closed", 5]])
      end

      # Cancelled meetings are excluded by MeetingQuery#default_scope, so the
      # value would never match anything.
      it "omits cancelled" do
        expect(instance.allowed_values.map(&:last)).not_to include(Meeting.states[:cancelled])
      end
    end
  end

  it_behaves_like "list query filter" do
    let(:attribute) { :state }
    let(:valid_values) { [Meeting.states[:closed].to_s] }
  end

  describe "#where clause" do
    shared_let(:project) { create(:project) }
    shared_let(:draft_meeting) { create(:meeting, project:, state: :draft) }
    shared_let(:open_meeting) { create(:meeting, project:, state: :open) }
    shared_let(:in_progress_meeting) { create(:meeting, project:, state: :in_progress) }
    shared_let(:closed_meeting) { create(:meeting, project:, state: :closed) }

    let(:instance) { described_class.create!(name: :state, operator:, values:) }

    subject(:meetings) { Meeting.where(instance.where) }

    context 'for "="' do
      let(:operator) { "=" }
      let(:values) { [Meeting.states[:in_progress].to_s, Meeting.states[:open].to_s] }

      it "finds the meetings in any of the selected statuses" do
        expect(meetings).to contain_exactly(open_meeting, in_progress_meeting)
      end
    end

    context 'for "!"' do
      let(:operator) { "!" }
      let(:values) { [Meeting.states[:closed].to_s] }

      it "finds the meetings in any other status" do
        expect(meetings).to contain_exactly(draft_meeting, open_meeting, in_progress_meeting)
      end
    end
  end
end
