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
require "services/work_packages/shared/shared_examples_days"

RSpec.describe Queries::NonWorkingDays::NonWorkingDayQuery do
  shared_let(:first_of_may) { create(:non_working_day, date: Date.new(Date.current.year, 5, 1)) }
  shared_let(:christmas) { create(:non_working_day, date: Date.new(Date.current.year, 12, 25)) }
  shared_let(:new_year_day) { create(:non_working_day, date: Date.new(Date.current.year + 1, 1, 1)) }

  let(:instance) { described_class.new }
  let(:base_scope) do
    NonWorkingDay
      .where(date: Date.current.all_year)
      .reorder(date: :asc)
  end

  let(:current_user) { build_stubbed(:admin) }

  before do
    login_as(current_user)
  end

  shared_examples "returns this year's non working days" do
    it "generates query for this year's non working days" do
      expect(instance.results.to_sql).to eql base_scope.to_sql
    end

    it "returns this year's non working days" do
      expect(instance.results).to eq [first_of_may, christmas]
    end
  end

  context "without a filter" do
    context "as an admin" do
      include_examples "returns this year's non working days"
    end

    context "as a non admin" do
      let(:current_user) { build_stubbed(:user) }

      include_examples "returns this year's non working days"
    end
  end

  context 'with a date filter using the "<>d" operator' do
    let(:date_range) { [from.iso8601, to.iso8601] }

    before do
      instance.where("date", "<>d", date_range)
    end

    context "with dates from this year" do
      let(:from) { Date.new(Date.current.year, 12, 1) }
      let(:to) { from.end_of_year }

      it "returns days from the December" do
        expect(instance.results).to eq [christmas]
      end

      context "with dates missing the to date" do
        let(:date_range) { [from.iso8601, ""] }

        it "returns days from December until the end of year" do
          expect(instance.results).to eq [christmas]
        end
      end

      context "with dates missing the from date" do
        let(:date_range) { ["", from.iso8601] }

        it "returns days from the beginning of the year until December" do
          expect(instance.results).to eq [first_of_may]
        end
      end
    end

    context "with dates from multiple years" do
      let(:from) { Date.current.beginning_of_year }
      let(:to) { Date.current.next_year.end_of_year }

      it "returns days from this year and next year" do
        expect(instance.results).to eq [first_of_may, christmas, new_year_day]
      end
    end
  end
end
