#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative 'shared_query_column_specs'

describe Queries::WorkPackages::Columns::CustomFieldColumn, type: :model do
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:custom_field) do
    mock_model(CustomField, field_format: 'string',
                            order_statements: nil)
  end
  let(:instance) { described_class.new(custom_field) }

  it_behaves_like 'query column'

  describe 'instances' do
    let(:text_custom_field) do
      FactoryBot.create(:text_wp_custom_field)
    end

    let(:list_custom_field) do
      FactoryBot.create(:list_wp_custom_field)
    end

    context 'within project' do
      before do
        allow(project)
          .to receive(:all_work_package_custom_fields)
          .and_return([text_custom_field,
                       list_custom_field])
      end

      it 'contains only non text cf columns' do
        expect(described_class.instances(project).length)
          .to eq 1

        expect(described_class.instances(project)[0].custom_field)
          .to eq list_custom_field
      end
    end

    context 'global' do
      before do
        allow(WorkPackageCustomField)
          .to receive(:all)
          .and_return([text_custom_field,
                       list_custom_field])
      end

      it 'contains only non text cf columns' do
        expect(described_class.instances.length)
          .to eq 1

        expect(described_class.instances[0].custom_field)
          .to eq list_custom_field
      end
    end
  end

  describe '#value' do
    let(:mock) { double(WorkPackage) }

    it 'delegates to formatted_custom_value_for' do
      expect(mock).to receive(:formatted_custom_value_for).with(custom_field.id)
      instance.value(mock)
    end
  end
end
