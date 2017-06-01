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
require_relative 'shared_query_column_specs'

describe ::QueryCustomFieldColumn, type: :model do
  let(:custom_field) {
    mock_model(CustomField, field_format: 'string',
                            order_statements: nil)
  }
  let(:instance) { described_class.new(custom_field) }

  it_behaves_like 'query column'

  describe '#available?' do
    context 'for text custom fields' do
      let(:custom_field) {
        mock_model(CustomField, field_format: 'text',
                                order_statements: nil)
      }

      it 'is false for long text custom fields' do
        expect(instance.available?).to be_falsey
      end
    end
  end

  describe '#value' do
    let(:mock) { double(WorkPackage) }

    it 'delegates to typed_custom_value_for' do
      expect(mock).to receive(:typed_custom_value_for).with(custom_field.id)
      instance.value(mock)
    end
  end
end
