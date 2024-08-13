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

RSpec.describe API::V3::Queries::ICalUrl::QueryICalUrlRepresenter do
  include API::V3::Utilities::PathHelper

  let(:query) { build_stubbed(:query) }
  let(:mocked_ical_url) { "https://community.openproject.org/projects/3/calendars/46/ical?ical_token=66a44f91a18ad0355cfad77c319ef5ee2973291499fb8e44a220885f9124d2d2" }
  let(:data_to_be_represented) do
    ical_url_data = Struct.new(:ical_url, :query)
    ical_url_data.new(mocked_ical_url, query)
  end
  let(:representer) do
    described_class.new(
      data_to_be_represented
    )
  end

  subject { representer.to_json }

  describe "generation" do
    describe "_links" do
      it_behaves_like "has an untitled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.query_ical_url(query.id) }
        let(:method) { "post" }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "query" }
        let(:href) { api_v3_paths.query(query.id) }
        let(:method) { "get" }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "icalUrl" }
        let(:href) { mocked_ical_url }
        let(:method) { "get" }
      end
    end

    it "has _type QueryICalUrl" do
      expect(subject)
        .to be_json_eql("QueryICalUrl".to_json)
        .at_path("_type")
    end
  end
end
