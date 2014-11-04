#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

end
