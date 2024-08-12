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

RSpec.describe API::V3::Queries::Filters::QueryFilterInstanceRepresenter do
  include API::V3::Utilities::PathHelper

  let(:operator) { "=" }
  let(:values) { [status.id.to_s] }

  let(:status) { build_stubbed(:status) }

  let(:filter) do
    f = Queries::WorkPackages::Filter::StatusFilter.create!
    f.operator = operator
    f.values = values

    f
  end

  let(:representer) { described_class.new(filter) }

  before do
    allow(filter)
      .to receive(:value_objects)
      .and_return([status])
  end

  describe "generation" do
    subject { representer.to_json }

    describe "_links" do
      it_behaves_like "has a titled link" do
        let(:link) { "filter" }
        let(:href) { api_v3_paths.query_filter "status" }
        let(:title) { "Status" }
      end

      it_behaves_like "has a titled link" do
        let(:link) { "operator" }
        let(:href) { api_v3_paths.query_operator(CGI.escape("=")) }
        let(:title) { "is (OR)" }
      end

      it_behaves_like "has an untitled link" do
        let(:link) { "schema" }
        let(:href) { api_v3_paths.query_filter_instance_schema "status" }
      end

      it "has a 'values' collection" do
        expected = {
          href: api_v3_paths.status(status.id.to_s),
          title: status.name
        }

        expect(subject)
          .to be_json_eql([expected].to_json)
          .at_path("_links/values")
      end

      it "renders templated values as part of the 'values' collection" do
        allow(filter)
          .to receive(:value_objects)
          .and_return([Queries::Filters::TemplatedValue.new(Status)])

        expected = {
          href: api_v3_paths.status("{id}"),
          title: nil,
          templated: true
        }

        expect(subject)
          .to be_json_eql([expected].to_json)
                .at_path("_links/values")
      end
    end

    it "has _type StatusQueryFilter" do
      expect(subject)
        .to be_json_eql("StatusQueryFilter".to_json)
        .at_path("_type")
    end

    it "has name Status" do
      expect(subject)
        .to be_json_eql("Status".to_json)
        .at_path("name")
    end

    context "with an invalid value_objects" do
      let(:filter) do
        f = Queries::WorkPackages::Filter::AssignedToFilter.create!
        f.operator = operator
        f.values = values

        f
      end
      let(:values) { ["1"] }

      before do
        allow(filter)
          .to receive(:value_objects)
                .and_return([User.anonymous])
      end

      it "has a 'values' collection" do
        expected = {
          href: nil,
          title: "Anonymous"
        }

        expect(subject)
          .to be_json_eql([expected].to_json)
                .at_path("_links/values")
      end
    end

    context "with a subproject filter value_objects" do
      shared_let(:admin) { create(:admin) }

      let(:project) { create(:project) }
      let(:subproject) { create(:project, parent: project) }
      let(:filter) do
        subproject
        project.reload

        f = Queries::WorkPackages::Filter::SubprojectFilter.create!(context: project)
        f.operator = "="
        f.values = [subproject.id]

        f
      end

      before do
        login_as admin

        allow(filter)
        .to receive(:value_objects)
        .and_call_original
      end

      it "has a 'values' collection" do
        expect(filter.value_objects.count).to eq 1
        expect(filter.value_objects.first).to eq subproject

        expected = {
          href: api_v3_paths.project(subproject.id.to_s),
          title: subproject.name
        }

        expect(subject)
          .to be_json_eql([expected].to_json)
                .at_path("_links/values")
      end
    end

    context "with a non ar object filter" do
      let(:values) { ["lorem ipsum"] }
      let(:filter) do
        f = Queries::WorkPackages::Filter::SubjectFilter.create!
        f.operator = operator
        f.values = values

        f
      end

      describe "_links" do
        it "has no values link" do
          expect(subject)
            .not_to have_json_path("_links/values")
        end
      end

      it "has a 'values' array property" do
        expect(subject)
          .to be_json_eql(values.to_json)
          .at_path("values")
      end
    end

    context "with a bool custom field filter" do
      let(:bool_cf) { create(:boolean_wp_custom_field) }
      let(:filter) do
        Queries::WorkPackages::Filter::CustomFieldFilter.create!(name: bool_cf.column_name, operator:, values:)
      end

      context "with 't' as filter value" do
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        it "has `true` for 'values'" do
          expect(subject)
            .to be_json_eql([true].to_json)
            .at_path("values")
        end
      end

      context "with 'f' as filter value" do
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        it "has `true` for 'values'" do
          expect(subject)
            .to be_json_eql([false].to_json)
            .at_path("values")
        end
      end

      context "with something as filter value" do
        let(:values) { ["blubs"] }

        it "has `true` for 'values'" do
          expect(subject)
            .to be_json_eql([false].to_json)
            .at_path("values")
        end
      end
    end
  end
end
