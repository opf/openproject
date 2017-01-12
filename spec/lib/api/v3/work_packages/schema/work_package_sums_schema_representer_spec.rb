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

describe ::API::V3::WorkPackages::Schema::WorkPackageSumsSchemaRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:available_custom_fields) { [] }
  let(:schema) { double('wp_schema', available_custom_fields: available_custom_fields) }
  let(:current_user) { double('user') }

  let(:representer) {
    described_class.create(schema, current_user: current_user)
  }
  let(:summable_columns) { [] }

  before do
    allow(Setting)
      .to receive(:work_package_list_summable_columns)
      .and_return(summable_columns)
  end

  subject { representer.to_json }

  context 'self link' do
    it 'has a self link' do
      expected = {
        href: api_v3_paths.work_package_sums_schema
      }

      expect(subject).to be_json_eql(expected.to_json).at_path('_links/self')
    end
  end

  context 'estimated_time' do
    context 'with it being configured to be summable' do
      let(:summable_columns) { ['estimated_hours'] }

      it 'is represented' do
        expected = { 'type': 'Duration',
                     'name': 'Estimated time',
                     'visibility': 'default',
                     'required': false,
                     'hasDefault': false,
                     'writable': false }
        expect(subject).to be_json_eql(expected.to_json).at_path('estimatedTime')
      end
    end

    context 'without it being configured to be summable' do
      it 'is not represented when the summable setting does not list it' do
        expect(subject).to_not have_json_path('estimatedTime')
      end
    end
  end

  context 'custom field x' do
    let(:custom_field)  { FactoryGirl.build_stubbed(:integer_issue_custom_field) }
    let(:available_custom_fields) { [custom_field] }

    context 'with it being configured to be summable' do
      let(:summable_columns) { ["cf_#{custom_field.id}"] }

      it 'is represented' do
        expected = { 'type': 'Integer',
                     'name': custom_field.name,
                     'visibility': 'default',
                     'required': false,
                     'hasDefault': false,
                     'writable': false }
        expect(subject).to be_json_eql(expected.to_json).at_path("customField#{custom_field.id}")
      end
    end

    context 'without it being configured to be summable' do
      it 'is not represented when the summable setting does not list it' do
        expect(subject).to_not have_json_path("customField#{custom_field.id}")
      end
    end
  end
end
