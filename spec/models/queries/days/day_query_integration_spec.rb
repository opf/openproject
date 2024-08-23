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

RSpec.describe Queries::Days::DayQuery do
  let(:instance) { described_class.new }
  let(:current_user) { build_stubbed(:admin) }

  before do
    login_as(current_user)
  end

  context "without a filter" do
    let(:from) { Date.current.at_beginning_of_month }
    let(:to) { from.next_month.at_end_of_month }

    let(:expected_size) { (to - from).to_i + 1 }

    context "as an admin" do
      it "is the same as getting all days in the month" do
        expect(instance.results.size).to be expected_size
      end
    end

    context "as a non admin" do
      let(:current_user) { build_stubbed(:user) }

      it "is the same as getting all days in the month" do
        expect(instance.results.size).to be expected_size
      end
    end
  end

  context 'with a date filter using the "<>d" operator' do
    let(:date_range) { [from.iso8601, to.iso8601] }

    before do
      instance.where("date", "<>d", date_range)
    end

    shared_examples_for "dates within the default range" do |working: nil|
      let(:from) { Date.current }
      let(:to) { Date.current + 6.days }

      let(:expected_size) do
        value = (to - from).to_i + 1
        value -= 2 if working
        value
      end

      before do
        Setting.working_days = "12345" if working
      end

      it "returns all the dates between the two dates#{working ? ' (only working)' : ''}" do
        expect(instance.results.size).to eql expected_size
      end
    end

    shared_examples_for "dates out of the default range" do
      let(:from) { 5.days.from_now.to_date }
      let(:to) { 153.days.from_now.to_date }

      it "returns all the days" do
        expect(instance.results.size).to eq 149
      end

      context "with dates missing the to date" do
        let(:date_range) { [from.iso8601, ""] }

        it "returns days until the end of next month" do
          expected_size = (from.next_month.at_end_of_month - from).to_i + 1
          expect(instance.results.size).to be expected_size
        end
      end

      context "with dates missing the from date" do
        let(:date_range) { ["", to.iso8601] }

        it "returns days from the beginning of the month" do
          expected_size = (to - to.at_beginning_of_month).to_i + 1
          expect(instance.results.size).to be expected_size
        end
      end
    end

    it_behaves_like "dates within the default range"
    it_behaves_like "dates out of the default range"

    context "when having a working filter too" do
      before do
        instance.where("working", "=", "t")
      end

      it_behaves_like "dates within the default range", working: true
      it_behaves_like "dates out of the default range"
    end
  end
end
