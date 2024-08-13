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

RSpec.describe API::V3::Days::WeekDayRepresenter do
  let(:week_day) { build(:week_day, day: 1) }
  let(:representer) { described_class.new(week_day, current_user: instance_double(User, name: "current_user")) }

  describe "#to_json" do
    subject(:generated) { representer.to_json }

    it "has _type: WeekDay" do
      expect(subject).to be_json_eql("WeekDay".to_json).at_path("_type")
    end

    it "has day integer property" do
      expect(subject).to have_json_type(Integer).at_path("day")
      expect(subject).to be_json_eql(week_day.day.to_json).at_path("day")
    end

    it "has name string property" do
      expect(subject).to have_json_type(String).at_path("name")
      expect(subject).to be_json_eql(week_day.name.to_json).at_path("name")
    end

    it "has working boolean property" do
      expect(subject).to have_json_type(TrueClass).at_path("working")
      expect(subject).to be_json_eql(week_day.working.to_json).at_path("working")
    end

    describe "_links" do
      it "is present" do
        expect(subject).to have_json_type(Object).at_path("_links")
      end

      describe "self" do
        it "links to this resource" do
          expected_json = {
            href: "/api/v3/days/week/#{week_day.day}",
            title: week_day.name
          }.to_json
          expect(subject).to be_json_eql(expected_json).at_path("_links/self")
        end
      end
    end
  end

  describe "caching" do
    it "is based on the representer's json_cache_key" do
      allow(OpenProject::Cache)
        .to receive(:fetch)
        .and_call_original

      representer.to_json

      expect(OpenProject::Cache)
        .to have_received(:fetch)
        .with(representer.json_cache_key)
    end

    describe "#json_cache_key" do
      let!(:former_cache_key) { representer.json_cache_key }

      it "includes the name of the representer class" do
        expect(representer.json_cache_key)
          .to include("API", "V3", "Days", "WeekDayRepresenter")
      end

      it "changes when the locale changes" do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it "changes when the Setting is updated" do
        set_week_days("tuesday")

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
