#-- encoding: UTF-8
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

shared_examples_for 'type service' do
  let(:success) { true }
  let(:params) { {} }

  describe '#call' do
    before do
      allow(type)
        .to receive(:save)
        .and_return(success)
    end

    it 'is successful' do
      expect(service_call).to be_success
    end

    it 'yields the block with success' do
      expect(service_call { |call| call.success? }).to be_truthy
    end

    describe 'with attributes' do
      let(:params) { { name: 'blubs blubs' } }

      it 'set the values provided on the call' do
        service_call

        expect(type.name).to eql params[:name]
      end
    end

    describe 'attribute groups' do
      context 'when not given' do
        let(:params) { { name: 'blubs blubs' } }

        it 'set the values provided on the call' do
          expect(type).not_to receive(:reset_attribute_groups)
          expect(type).not_to receive(:attribute_groups=)

          service_call

          expect(type.name).to eql params[:name]
        end
      end

      context 'when empty' do
        let(:params) { { attribute_groups: [] } }

        it 'set the values provided on the call' do
          expect(type).to receive(:reset_attribute_groups)
          expect(type).not_to receive(:attribute_groups=)

          service_call
        end
      end

      context 'when other' do
        let(:params) { { attribute_groups: [{ 'type' => 'attribute', 'name' => 'foo', 'attributes' => [] }] } }

        it 'set the values provided on the call' do
          expect(type).not_to receive(:reset_attribute_groups)
          expect(type).to receive(:attribute_groups=)

          service_call
        end
      end
    end

    describe 'custom fields' do
      let(:cf1) { FactoryBot.create :work_package_custom_field, field_format: 'text' }
      let(:cf2) { FactoryBot.create :work_package_custom_field, field_format: 'text' }
      let(:params) do
        {
          attribute_groups: [
            { 'type' => 'attribute',
              'name' => 'group1',
              'attributes' => [{ 'key' => "custom_field_#{cf1.id}" }, { 'key' => 'custom_field_54' }] },
            { 'type' => 'attribute',
              'name' => 'groups',
              'attributes' => [{ 'key' => "custom_field_#{cf2.id}" }] }
          ]
        }
      end

      it 'enables the custom fields that are passed via attribute_groups' do
        allow(type)
          .to receive(:work_package_attributes)
          .and_return("custom_field_#{cf1.id}" => {}, "custom_field_#{cf2.id}" => {})

        expect(type)
          .to receive(:custom_field_ids=)
          .with([cf1.id, cf2.id])

        service_call
      end
    end

    describe 'query group' do
      let(:query_params) do
        sort_by = JSON::dump(['status:desc'])
        filters = JSON::dump([{ 'status_id' => { 'operator' => '=', 'values' => %w(1 2) } }])

        { 'sortBy' => sort_by, 'filters' => filters }
      end
      let(:query_group_params) do
        { 'type' => 'query', 'name' => 'group1', 'query' => JSON.dump(query_params) }
      end
      let(:params) { { attribute_groups: [query_group_params] } }
      let(:query) { FactoryBot.create(:query, user_id: 0) }
      let(:service_result) { ServiceResult.new(success: true, result: query) }

      before do
        allow(Query)
          .to receive(:new_default)
          .with(name: "Embedded table: group1")
          .and_return(query)

        parse_service = double('ParseQueryParamsService')
        allow(::API::V3::UpdateQueryFromV3ParamsService)
          .to receive(:new)
          .with(query, user)
          .and_return(parse_service)

        allow(parse_service)
          .to receive(:call)
          .with(query_params)
          .and_return(service_result)
      end

      it 'assigns the fully parsed query to the type\'s attribute group' do
        expect(service_call).to be_success

        expect(type.attribute_groups[0].query)
          .to eql query

        expect(query.filters.length)
          .to eql 1

        expect(query.filters[0].name)
          .to eql :status_id
      end

      context 'when the query service reports an error' do
        let(:success) { false }
        let(:service_result) { ServiceResult.new(success: false, result: nil) }

        it 'reports the error' do
          expect(service_call).to be_failure

          expect(type.attribute_groups[0].query)
            .to eql query
        end
      end
    end

    context 'on failure' do
      let(:success) { false }
      let(:params) { { name: nil } }

      subject { service_call }

      it 'returns a failed service result' do
        expect(subject).not_to be_success
      end

      it 'returns the errors of the type' do
        type.name = nil
        expect(subject.errors.symbols_for(:name)).to include :blank
      end
    end
  end
end
