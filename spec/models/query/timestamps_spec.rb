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

RSpec.describe Query::Timestamps,
               with_ee: %i[baseline_comparison] do
  describe "#timestamps" do
    subject { query.timestamps }

    describe "after setting timestamps to an array of ISO8601 Strings" do
      let(:query) { Query.new }

      before { query.timestamps = ["P-50Y", "2022-10-29T23:01:23Z"] }

      it "returns an Array of Timestamp objects" do
        expect(subject).to be_a Array
        expect(subject.map(&:class).uniq).to eq [Timestamp]
      end

      it "remembers which timestamp encodes a relative time" do
        expect(subject.first.relative?).to be true
        expect(subject.last.relative?).to be false
      end
    end

    describe "after setting timestamps to an array of Times" do
      let(:query) { Query.new }

      before { query.timestamps = [50.years.ago, Time.zone.now] }

      it "returns an Array of Timestamp objects" do
        expect(subject).to be_a Array
        expect(subject.map(&:class).uniq).to eq [Timestamp]
      end
    end

    describe "when not present" do
      let(:query) { Query.new }

      before { query.timestamps = [] }

      it "still returns the timestamp corresponding to the present time" do
        expect(subject).to eq [Timestamp.now]
      end
    end

    describe "[persistence] when saving timestamps to a record" do
      let(:query) { create(:query) }

      before do
        query.timestamps = ["P-50Y", "2022-10-29T23:01:23Z"]
        query.save!
      end

      describe "after reloading the record from the database" do
        let(:reloaded_query) { Query.find(query.id) }

        subject { reloaded_query.timestamps }

        it "returns an Array of Timestamp objects" do
          expect(subject).to be_a Array
          expect(subject.map(&:class).uniq).to eq [Timestamp]
        end

        it "remembers which timestamp encodes a relative time" do
          expect(subject.first.relative?).to be true
          expect(subject.last.relative?).to be false
        end

        it "remembers the timestamp values" do
          expect(subject.first).to eq "P-50Y"
          expect(subject.last).to eq "2022-10-29T23:01:23Z"
        end
      end
    end
  end
end
