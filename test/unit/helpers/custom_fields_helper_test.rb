#-- encoding: UTF-8
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
require File.expand_path('../../../test_helper', __FILE__)

class CustomFieldsHelperTest < HelperTestCase
  include CustomFieldsHelper
  include Redmine::I18n

  def test_format_boolean_value
    I18n.locale = 'en'
    assert_equal 'Yes', format_value('1', 'bool')
    assert_equal 'No', format_value('0', 'bool')
  end

  def test_unknow_field_format_should_be_edited_as_string
    field = CustomField.new(field_format: 'foo')
    value = CustomValue.new(value: 'bar', custom_field: field)
    field.id = 52

    assert_match '<input id="object_custom_field_values_52" name="object[custom_field_values][52]" type="text" value="bar" />',
                 custom_field_tag('object', value)
  end

  def test_unknow_field_format_should_be_bulk_edited_as_string
    field = CustomField.new(field_format: 'foo')
    field.id = 52

    assert_equal '<input id="object_custom_field_values_52" name="object[custom_field_values][52]" type="text" value="" />',
                 custom_field_tag_for_bulk_edit('object', field)
  end
end
