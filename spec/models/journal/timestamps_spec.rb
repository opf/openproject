#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'

describe Journal::Timestamps, type: :model do

  let!(:work_package) { create :work_package }
  let(:journable) { work_package }

  describe ".at_timestamp" do
    before { @timestamp = Time.zone.now }
    subject { Journal.at_timestamp(@timestamp) }

    it "returns an active-record relation" do
      expect(subject).to be_kind_of ActiveRecord::Relation
    end

    describe "when appended to a where clause" do
      subject { Journal.where(user_id: work_package.author_id).at_timestamp(@timestamp) }
      it "returns an active-record relation" do
        expect(subject).to be_kind_of ActiveRecord::Relation
      end
    end
    describe "when prepended to a where clause" do
      subject { Journal.at_timestamp(@timestamp).where(user_id: work_package.author_id) }
      it "returns an active-record relation" do
        expect(subject).to be_kind_of ActiveRecord::Relation
      end
    end

    describe "when the given timestamp is nil" do
      before { @timestamp = nil }
      it "raises an error" do
        expect { subject }.to raise_error ArgumentError
      end
    end
    describe "when the given timestamp is nonsense" do
      before { @timestamp = "FOO BAR" }
      it "raises an error" do
        expect { subject }.to raise_error ArgumentError
      end
    end
    describe "when the given timestamp is given as DateTime" do
      before { @timestamp = DateTime.current }
      it "raises no error" do
        expect { subject }.not_to raise_error
      end
    end
    describe "when the given timestamp is given as ActiveSupport::TimeWithZone" do
      before { @timestamp = Time.zone.now }
      it "raises no error" do
        expect(@timestamp).to be_kind_of ActiveSupport::TimeWithZone
        expect { subject }.not_to raise_error
      end
    end

    describe "when there are journals for Monday, Wednesday, and Friday" do
      before do
        @before_monday = "2022-01-01".to_datetime
        @monday = "2022-08-01".to_datetime
        @tuesday = "2022-08-02".to_datetime
        @wednesday = "2022-08-03".to_datetime
        @thursday = "2022-08-04".to_datetime
        @friday = "2022-08-05".to_datetime
        work_package.journals.destroy_all
        @monday_journal = create :work_package_journal, journable: work_package, created_at: @monday
        @wednesday_journal = create :work_package_journal, journable: work_package, created_at: @wednesday
        @friday_journal = create :work_package_journal, journable: work_package, created_at: @friday
      end

      describe ".at_timestamp(something before Monday)" do
        before { @timestamp = @before_monday }
        it "returns [] because before Monday, no journal exists" do
          expect(subject).to eq []
        end
      end
      describe ".at_timestamp(Monday)" do
        before { @timestamp = @monday }
        it "returns only the Monday journal because this is the most current on Monday" do
          expect(subject).to eq [@monday_journal]
        end
      end
      describe ".at_timestamp(Tuesday)" do
        before { @timestamp = @tuesday }
        it "returns only the Monday journal because this is the most current on Tuesday" do
          expect(subject).to eq [@monday_journal]
        end
      end
      describe ".at_timestamp(Wednesday)" do
        before { @timestamp = @wednesday }
        it "returns only the Wednesday journal because this is the most current on Wednesday" do
          expect(subject).to eq [@wednesday_journal]
        end
      end
      describe ".at_timestamp(Thursday)" do
        before { @timestamp = @thursday }
        it "returns only the Wednesday journal because this is the most current on Thursday" do
          expect(subject).to eq [@wednesday_journal]
        end
      end
      describe ".at_timestamp(Friday)" do
        before { @timestamp = @friday }
        it "returns only the Friday journal because this is the most current on Friday" do
          expect(subject).to eq [@friday_journal]
        end
      end

      describe "when at_timestamp is called on an association" do
        subject { journable.journals.at_timestamp(@timestamp) }

        describe ".at_timestamp(something before Monday)" do
          before { @timestamp = @before_monday }
          it "returns [] because before Monday, no journal exists" do
            expect(subject).to eq []
          end
        end
        describe ".at_timestamp(Monday)" do
          before { @timestamp = @monday }
          it "returns only the Monday journal because this is the most current on Monday" do
            expect(subject).to eq [@monday_journal]
          end
        end
        describe ".at_timestamp(Tuesday)" do
          before { @timestamp = @tuesday }
          it "returns only the Monday journal because this is the most current on Tuesday" do
            expect(subject).to eq [@monday_journal]
          end
        end
        describe ".at_timestamp(Wednesday)" do
          before { @timestamp = @wednesday }
          it "returns only the Wednesday journal because this is the most current on Wednesday" do
            expect(subject).to eq [@wednesday_journal]
          end
        end
        describe ".at_timestamp(Thursday)" do
          before { @timestamp = @thursday }
          it "returns only the Wednesday journal because this is the most current on Thursday" do
            expect(subject).to eq [@wednesday_journal]
          end
        end
        describe ".at_timestamp(Friday)" do
          before { @timestamp = @friday }
          it "returns only the Friday journal because this is the most current on Friday" do
            expect(subject).to eq [@friday_journal]
          end
        end
      end
    end

  end
end
