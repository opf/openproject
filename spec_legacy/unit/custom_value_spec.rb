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
require_relative '../legacy_spec_helper'

describe CustomValue, type: :model do
  it 'should string field validation with blank value' do
    f = CustomField.new(field_format: 'string')
    v = CustomValue.new(custom_field: f)

    v.value = nil
    assert v.valid?
    v.value = ''
    assert v.valid?

    f.is_required = true
    v.value = nil
    assert !v.valid?
    v.value = ''
    assert !v.valid?
  end

  it 'should string field validation with min and max lengths' do
    f = CustomField.new(field_format: 'string', min_length: 2, max_length: 5)
    v = CustomValue.new(custom_field: f, value: '')
    assert v.valid?
    v.value = 'a'
    assert !v.valid?
    v.value = 'a' * 2
    assert v.valid?
    v.value = 'a' * 6
    assert !v.valid?
  end

  it 'should string field validation with regexp' do
    f = CustomField.new(field_format: 'string', regexp: '^[A-Z0-9]*$')
    v = CustomValue.new(custom_field: f, value: '')
    assert v.valid?
    v.value = 'abc'
    assert !v.valid?
    v.value = 'ABC'
    assert v.valid?
  end

  it 'should date field validation' do
    f = CustomField.new(field_format: 'date')
    v = CustomValue.new(custom_field: f, value: '')
    assert v.valid?
    v.value = 'abc'
    assert !v.valid?
    v.value = '1975-07-14'
    assert v.valid?
  end

  it 'should list field validation' do
    f = CustomField.create(field_format: 'list', possible_values: ['value1', 'value2'])
    v = CustomValue.new(custom_field: f, value: '')
    assert v.valid?
    v.value = 'abc'
    assert !v.valid?
    v.value = f.custom_options.first.id
    assert v.valid?
  end

  it 'should int field validation' do
    f = CustomField.new(field_format: 'int')
    v = CustomValue.new(custom_field: f, value: '')
    assert v.valid?
    v.value = 'abc'
    assert !v.valid?
    v.value = '123'
    assert v.valid?
    v.value = '+123'
    assert v.valid?
    v.value = '-123'
    assert v.valid?
  end

  it 'should float field validation' do
    user = FactoryBot.create :user
    # There are cases, where the custom-value-table is not cleared completely,
    # therefore making double sure, that we have a clean slate before we start
    CustomField.destroy_all
    FactoryBot.create :float_user_custom_field, name: 'Money'
    v = CustomValue.new(customized: user, custom_field: UserCustomField.find_by(name: 'Money'))
    v.value = '11.2'
    assert v.save
    v.value = ''
    assert v.save
    v.value = '-6.250'
    assert v.save
    v.value = '6a'
    assert !v.save
  end

  it 'should sti polymorphic association' do
    # Rails uses top level sti class for polymorphic association. See #3978.
    user = FactoryBot.create :user
    custom_field = FactoryBot.create :user_custom_field, field_format: 'string'
    custom_value = FactoryBot.create :principal_custom_value,
                                      custom_field: custom_field,
                                      customized: user,
                                      value: '01 23 45 67 89'
    user.reload

    assert !user.custom_values.empty?
    assert !custom_value.customized.nil?
  end
end
