#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Queries::Filters::QueryFilterInstanceRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:operator) { '=' }
  let(:values) { [status.id.to_s] }

  let(:status) { FactoryGirl.build_stubbed(:status) }

  let(:filter) do
    Queries::WorkPackages::Filter::StatusFilter.new(operator: operator, values: values)
  end

  let(:representer) { described_class.new(filter) }

  before do
    allow(filter)
      .to receive(:value_objects)
      .and_return([status])
  end

  describe 'generation' do
    subject { representer.to_json }

    describe '_links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'filter' }
        let(:href) { api_v3_paths.query_filter 'status' }
        let(:title) { 'Status' }
      end

      it_behaves_like 'has a titled link' do
        let(:link) { 'operator' }
        let(:href) { api_v3_paths.query_operator(CGI.escape('=')) }
        let(:title) { 'is' }
      end

      it_behaves_like 'has an untitled link' do
        let(:link) { 'schema' }
        let(:href) { api_v3_paths.query_filter_instance_schema 'status' }
      end

      it "has a 'values' collection" do
        expected = {
          href: api_v3_paths.status(status.id.to_s),
          title: status.name
        }

        is_expected
          .to be_json_eql([expected].to_json)
          .at_path('_links/values')
      end
    end

    it 'has _type StatusQueryFilter' do
      is_expected
        .to be_json_eql('StatusQueryFilter'.to_json)
        .at_path('_type')
    end

    it 'has name Status' do
      is_expected
        .to be_json_eql('Status'.to_json)
        .at_path('name')
    end

    context 'with a non ar object filter' do
      let(:values) { ['lorem ipsum'] }
      let(:filter) do
        Queries::WorkPackages::Filter::SubjectFilter.new(operator: operator, values: values)
      end

      describe '_links' do
        it 'has no values link' do
          is_expected
            .not_to have_json_path('_links/values')
        end
      end

      it "has a 'values' array property" do
        is_expected
          .to be_json_eql(values.to_json)
          .at_path('values')
      end
    end

    context 'with a bool custom field filter' do
      let(:bool_cf) { FactoryGirl.build_stubbed(:bool_wp_custom_field) }
      let(:filter) do
        filter = Queries::WorkPackages::Filter::CustomFieldFilter.new(operator: operator, values: values)
        filter.custom_field = bool_cf
        filter
      end

      context "with 't' as filter value" do
        let(:values) { [CustomValue::BoolStrategy::DB_VALUE_TRUE] }

        it "has `true` for 'values'" do
          is_expected
            .to be_json_eql([true].to_json)
            .at_path('values')
        end
      end

      context "with 'f' as filter value" do
        let(:values) { [CustomValue::BoolStrategy::DB_VALUE_FALSE] }

        it "has `true` for 'values'" do
          is_expected
            .to be_json_eql([false].to_json)
            .at_path('values')
        end
      end

      context "with something as filter value" do
        let(:values) { ['blubs'] }

        it "has `true` for 'values'" do
          is_expected
            .to be_json_eql([false].to_json)
            .at_path('values')
        end
      end
    end
  end
end
