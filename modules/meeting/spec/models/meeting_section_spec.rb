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

require_relative "../spec_helper"

RSpec.describe MeetingSection do
  let(:meeting_attributes) { {} }
  let(:meeting) { build_stubbed(:structured_meeting, **meeting_attributes) }
  let(:attributes) { {} }
  let(:meeting_section) { described_class.new(meeting:, **attributes) }

  subject { meeting_section }

  describe "#title" do
    let(:attributes) { { title: } }

    context "when title is blank" do
      let(:title) { "" }

      it "is allowed" do
        expect(subject).to be_valid
      end
    end

    context "when title is present" do
      let(:title) { "My section" }

      it "validates" do
        expect(subject).to be_valid
        expect(subject.title).to eq "My section"
      end
    end
  end

  describe "#modifiable?" do
    subject { meeting_section.modifiable? }

    let(:attributes) { {} }

    context "when meeting is closed" do
      let(:meeting_attributes) { { state: :closed } }

      it { is_expected.to be false }
    end
  end

  describe "#agenda_items_sum_duration_in_minutes" do
    subject { meeting_section.agenda_items_sum_duration_in_minutes }

    let(:meeting) { create(:structured_meeting, **meeting_attributes) }
    let(:meeting_section) { create(:meeting_section, meeting:) }

    context "when there are no agenda items" do
      it { is_expected.to eq 0 }
    end

    context "when there are agenda items" do
      let!(:agenda_item) { create(:meeting_agenda_item, meeting_section:, duration_in_minutes: 15) }

      it { is_expected.to eq 15 }
    end
  end
end
