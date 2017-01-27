#-- encoding: UTF-8
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
require_relative '../legacy_spec_helper'

describe CustomField, type: :model do
  it 'should create' do
    field = UserCustomField.new(name: 'Money money money', field_format: 'float')
    assert field.save
  end

  it 'should possible values should accept an array' do
    field = CustomField.new field_format: "list"
    field.possible_values = ['One value', '']
    assert_equal ['One value'], field.possible_values.map(&:value)
  end

  it 'should possible values should accept a string' do
    field = CustomField.new field_format: "list"
    field.possible_values = 'One value'
    assert_equal ['One value'], field.possible_values.map(&:value)
  end

  it 'should possible values should accept a multiline string' do
    field = CustomField.new field_format: "list"
    field.possible_values = "One value\nAnd another one  \r\n \n"
    assert_equal ['One value', 'And another one'], field.possible_values.map(&:value)
  end

  it 'should destroy' do
    field = FactoryGirl.create :custom_field
    assert field.destroy
  end
end
