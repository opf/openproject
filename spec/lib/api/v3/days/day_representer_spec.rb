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

RSpec.describe API::V3::Days::DayRepresenter do
  let(:working) { true }
  let(:date) { Date.new(2022, 12, 27) }
  let(:day) do
    Day.from_range(from: Date.new(2022, 12, 1), to: Date.new(2022, 12, 31))
       .find(date.strftime("%Y%m%d").to_i)
  end
  let(:current_user) { instance_double(User, name: "current_user") }
  let(:representer) { described_class.new(day, current_user:) }

  subject(:generated) { representer.to_json }

  before do
    set_week_days("tuesday", working:)
  end

  it "has _type: Day" do
    expect(subject).to be_json_eql("Day".to_json).at_path("_type")
  end

  it "has date property" do
    expect(subject).to have_json_type(String).at_path("date")
    expect(subject).to be_json_eql("2022-12-27".to_json).at_path("date")
  end

  it "has name string property" do
    expect(subject).to have_json_type(String).at_path("name")
    expect(subject).to be_json_eql(day.name.to_json).at_path("name")
  end

  it "has working boolean property" do
    expect(subject).to have_json_type(TrueClass).at_path("working")
    expect(subject).to be_json_eql(day.working.to_json).at_path("working")
  end

  describe "_links" do
    it "is present" do
      expect(subject).to have_json_type(Object).at_path("_links")
    end

    describe "self" do
      it "links to this resource" do
        expected_json = {
          href: "/api/v3/days/2022-12-27",
          title: "Tuesday"
        }.to_json
        expect(subject).to be_json_eql(expected_json).at_path("_links/self")
      end
    end

    describe "nonWorkingReasons" do
      context "when the day has working true" do
        it { is_expected.not_to have_json_path("_links/nonWorkingReasons") }
      end

      context "when day has working false" do
        let(:working) { false }

        it "links to the day resource" do
          expected_json = [{
            href: "/api/v3/days/week/2",
            title: "Tuesday"
          }].to_json

          expect(subject).to be_json_eql(expected_json).at_path("_links/nonWorkingReasons")
        end
      end

      context "when a non-working day is present" do
        let!(:non_working_day) { create(:non_working_day, date:) }

        it "links to the non-working day resource" do
          expected_json = [{
            href: "/api/v3/days/non_working/2022-12-27",
            title: non_working_day.name
          }].to_json

          expect(subject).to be_json_eql(expected_json).at_path("_links/nonWorkingReasons")
        end
      end

      context "when the day has working false and a non-working day is present" do
        let(:working) { false }
        let!(:non_working_day) { create(:non_working_day, date:) }

        it "links to the day resource and to the non-working day resource" do
          expected_json = [{
            href: "/api/v3/days/week/2",
            title: "Tuesday"
          }, {
            href: "/api/v3/days/non_working/2022-12-27",
            title: non_working_day.name
          }].to_json

          expect(subject).to be_json_eql(expected_json).at_path("_links/nonWorkingReasons")
        end
      end
    end

    describe "weekday" do
      it "links to the weekday resource" do
        expected_json = {
          href: "/api/v3/days/week/2",
          title: "Tuesday"
        }.to_json

        expect(subject).to be_json_eql(expected_json).at_path("_links/weekday")
      end
    end
  end
end
