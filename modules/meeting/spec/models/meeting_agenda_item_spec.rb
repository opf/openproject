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

RSpec.describe MeetingAgendaItem do
  let(:meeting_attributes) { {} }
  let(:meeting) { build_stubbed(:structured_meeting, **meeting_attributes) }
  let(:attributes) { {} }
  let(:meeting_agenda_item) { described_class.new(meeting:, **attributes) }

  subject { meeting_agenda_item }

  describe "#author" do
    let(:attributes) { { title: "foo", author: } }

    context "when author is missing" do
      let(:author) { nil }

      it "validates" do
        expect(subject).not_to be_valid
        expect(subject.errors[:author]).to include "must exist"
      end
    end

    context "when author is present" do
      let(:author) { build_stubbed(:user) }

      it "validates" do
        expect(subject).to be_valid
      end
    end
  end

  describe "#duration" do
    let(:attributes) { { title: "foo", author: build_stubbed(:user), duration_in_minutes: } }

    context "with a valid duration" do
      let(:duration_in_minutes) { 60 }

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "with a negative duration" do
      let(:duration_in_minutes) { -1 }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:duration_in_minutes]).to include "must be greater than or equal to 0."
      end
    end

    context "with a duration that is too large" do
      let(:duration_in_minutes) { 10000000000 }

      it "is valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:duration_in_minutes]).to include "must be less than or equal to 1440."
      end
    end

    context "with max duration" do
      let(:duration_in_minutes) { 1440 }

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "with overmax duration" do
      let(:duration_in_minutes) { 1441 }

      it "is valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:duration_in_minutes]).to include "must be less than or equal to 1440."
      end
    end
  end

  describe "#title" do
    let(:attributes) { { title:, item_type:, author: build_stubbed(:user), work_package_id: 1 } }

    context "when item_type is simple" do
      let(:item_type) { :simple }

      context "and title is missing" do
        let(:title) { nil }

        it { is_expected.not_to be_valid }
      end

      context "and title is present" do
        let(:title) { "title" }

        it { is_expected.to be_valid }
      end
    end

    context "when item_type is work_package and title is missing" do
      let(:item_type) { :work_package }
      let(:title) { nil }

      it { is_expected.to be_valid }
    end
  end

  describe "#work_package_id" do
    let(:attributes) { { work_package_id:, item_type:, author: build_stubbed(:user), title: "title" } }

    context "on create" do
      context "when item_type is simple" do
        let(:item_type) { :simple }

        context "and work_package_id is missing" do
          let(:work_package_id) { nil }

          it { is_expected.to be_valid }
        end

        context "and work_package_id is present" do
          let(:work_package_id) { 1 }

          it { is_expected.to be_valid }
        end
      end

      context "when item_type is work_package" do
        let(:item_type) { :work_package }

        context "and work_package_id is missing" do
          let(:work_package_id) { nil }

          it { is_expected.not_to be_valid }
        end

        context "and work_package_id is present" do
          let(:work_package_id) { 1 }

          it { is_expected.to be_valid }
        end
      end
    end

    context "on update" do
      let(:meeting_agenda_item) { create(:meeting_agenda_item) }

      subject do
        meeting_agenda_item.assign_attributes(attributes)
        meeting_agenda_item
      end

      context "when item_type is simple" do
        let(:item_type) { :simple }

        context "and work_package_id is missing" do
          let(:work_package_id) { nil }

          it { is_expected.to be_valid }
        end

        context "and work_package_id is present" do
          let(:work_package_id) { 1 }

          it { is_expected.to be_valid }
        end
      end

      context "when item_type is work_package" do
        let(:item_type) { :work_package }

        context "and work_package_id is missing" do
          let(:work_package_id) { nil }

          it { is_expected.to be_valid }
        end

        context "and work_package_id is present" do
          let(:work_package_id) { 1 }

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe "#deleted_work_package?" do
    subject { meeting_agenda_item.deleted_work_package? }

    let(:attributes) { { work_package_id:, item_type: } }

    context 'when item_type is not "work_package"' do
      let(:item_type) { :simple }
      let(:work_package_id) { nil }

      context "and the agenda_item is not persisted" do
        it { is_expected.to be false }
      end

      context "and the agenda_item is persisted" do
        let(:meeting_agenda_item) { build_stubbed(:meeting_agenda_item, meeting:, **attributes) }

        it { is_expected.to be false }
      end
    end

    context 'when item_type is "work_package"' do
      let(:item_type) { :work_package }

      context "and the agenda_item is not persisted" do
        context "and work_package_id is missing" do
          let(:work_package_id) { nil }

          it { is_expected.to be false }
        end

        context "and work_package_id is present" do
          let(:work_package_id) { 1 }

          it { is_expected.to be false }
        end
      end

      context "and the agenda_item is persisted" do
        let(:meeting_agenda_item) { build_stubbed(:meeting_agenda_item, meeting:, **attributes) }

        context "and work_package_id was originally missing" do
          let(:work_package_id) { nil }

          context "and now is present" do
            before do
              meeting_agenda_item.work_package_id = 1
            end

            it { is_expected.to be true }
          end

          context "and now is also missing" do
            it { is_expected.to be true }
          end
        end

        context "and work_package_id was originally present" do
          let(:work_package_id) { 1 }

          context "and now is also present" do
            it { is_expected.to be false }
          end

          context "and now is missing" do
            before do
              meeting_agenda_item.work_package_id = nil
            end

            it { is_expected.to be false }
          end
        end
      end
    end
  end

  describe "#modifiable?" do
    subject { meeting_agenda_item.modifiable? }

    let(:attributes) { { work_package_id: nil, item_type: :work_package } }

    context "when meeting is closed" do
      let(:meeting_attributes) { { state: :closed } }

      it { is_expected.to be false }
    end

    context "when the work package is not deleted" do
      before do
        allow(meeting_agenda_item).to receive(:deleted_work_package?).and_return(false)
      end

      it { is_expected.to be true }
    end

    context "when work package is deleted" do
      before do
        allow(meeting_agenda_item).to receive(:deleted_work_package?).and_return(true)
      end

      context "and the current value is not modified" do
        it { is_expected.to be true }
      end

      context "and the current value is modified" do
        before do
          meeting_agenda_item.work_package_id = 1
        end

        it { is_expected.to be false }
      end
    end
  end
end
