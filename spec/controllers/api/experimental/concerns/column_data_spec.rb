#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'ColumnData', type: :controller do
  include Api::Experimental::Concerns::ColumnData

  let(:field_format) { 'user' }
  let(:field) { double('field', id: 1, order_statement: '', field_format: field_format) }

  describe '#column_data_type' do
    it 'should recognise custom field columns based on field format' do
      field  = double('field', id: 1, order_statement: '', field_format: 'user')
      column = ::QueryCustomFieldColumn.new(field)

      expect(column_data_type(column)).to eq('user')
    end

    it 'should recognise Currency columns based on class name' do
      DodgeCoinCurrencyQueryColumn = Class.new(QueryColumn)
      column = DodgeCoinCurrencyQueryColumn.new('overspend')

      expect(column_data_type(column)).to eq('currency')
    end

    xit 'should test the full gamut of types'
  end

  describe '#link_meta' do
    let(:cf_column) { ::QueryCustomFieldColumn.new(field) }

    describe 'for version custom fields' do
      let(:field_format) { 'version' }

      it 'has display true' do
        expect(link_meta(cf_column)[:display]).to be_truthy
      end

      it 'has the model_type set to "version"' do
        expect(link_meta(cf_column)[:model_type]).to eql(field_format)
      end
    end

    describe 'for user custom fields' do
      let(:field_format) { 'user' }

      it 'has display true' do
        expect(link_meta(cf_column)[:display]).to be_truthy
      end

      it 'has the model_type set to "user"' do
        expect(link_meta(cf_column)[:model_type]).to eql(field_format)
      end
    end

    describe 'for int custom fields' do
      let(:field_format) { 'int' }

      it 'has display false' do
        expect(link_meta(cf_column)[:display]).to be_falsey
      end

      it 'lacks a model_type' do
        expect(link_meta(cf_column)[:model_type]).to be_nil
      end
    end
  end

  describe '#include_columns' do
    let(:regular_columns) { ['type'] }

    context 'regular fields' do
      let(:bogus_columns) { ['bogus'] }

      it 'includes nothing empty column names' do
        expect(includes_for_columns([])).to eq([])
      end

      it 'includes mutual fields' do
        expect(includes_for_columns(regular_columns)).to eq([:type])
      end

      it 'excludes bogus columns' do
        expect(includes_for_columns(regular_columns | bogus_columns)).to eq([:type])
      end
    end

    context 'custom fields' do
      let(:custom_fields) { ['cf_1'] }

      it 'includes custom fields' do
        expect(includes_for_columns(custom_fields)).to eq([{ custom_values: :custom_field }])
      end

      it 'includes custom fields and regular fields' do
        columns = custom_fields | regular_columns
        expect(includes_for_columns(columns)).to eq([:type, { custom_values: :custom_field }])
      end
    end
  end
end
