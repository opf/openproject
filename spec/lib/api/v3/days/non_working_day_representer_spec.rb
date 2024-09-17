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

RSpec.describe API::V3::Days::NonWorkingDayRepresenter do
  let(:non_working_day) { build_stubbed(:non_working_day, name: "Christmas day", date: Date.tomorrow) }
  let(:representer) { described_class.new(non_working_day, current_user: instance_double(User, name: "current_user")) }

  describe "#to_json" do
    subject(:generated) { representer.to_json }

    it_behaves_like "property", :_type do
      let(:value) { "NonWorkingDay" }
    end

    it_behaves_like "property", :id do
      let(:value) { non_working_day.id }
    end

    it_behaves_like "property", :name do
      let(:value) { non_working_day.name }
    end

    it_behaves_like "has ISO 8601 date only" do
      let(:date) { non_working_day.date }
      let(:json_path) { "date" }
    end

    describe "_links" do
      it "is present" do
        expect(subject).to have_json_type(Object).at_path("_links")
      end

      describe "self" do
        it "links to this resource" do
          expected_json = {
            href: "/api/v3/days/non_working/#{non_working_day.date}",
            title: non_working_day.name
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
          .to include("API", "V3", "Days", "NonWorkingDayRepresenter")
      end

      it "changes when the locale changes" do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it "changes when the non_working_day is updated" do
        non_working_day.updated_at = 20.seconds.from_now

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
