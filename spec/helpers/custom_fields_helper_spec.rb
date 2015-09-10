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
require 'spec_helper'

describe CustomFieldsHelper, type: :helper do
  include OpenProject::FormTagHelper
  include CustomFieldsHelper
  include Redmine::I18n

  it 'should format boolean value' do
    I18n.locale = 'en'
    expect(format_value('1', 'bool')).to eq 'Yes'
    expect(format_value('0', 'bool')).to eq 'No'
  end

  it 'unknown field format should be edited as string' do
    field = CustomField.new(field_format: 'foo')
    value = CustomValue.new(value: 'bar', custom_field: field)
    field.id = 52

    expect(custom_field_tag('object', value)).to be_html_eql(%{
      <span lang="en">
        <span class="form--text-field-container">
          <input class="form--text-field"
                 id="object_custom_field_values_52"
                 name="object[custom_field_values][52]"
                 type="text"
                 value="bar" />
        </span>
      </span>
    })
  end

  it 'unknown field format should be bulk edited as string' do
    field = CustomField.new(field_format: 'foo')
    field.id = 52

    expect(custom_field_tag_for_bulk_edit('object', field)).to be_html_eql(%{
      <span class="form--text-field-container"><input class="form--text-field"
            id="object_custom_field_values_52" name="object[custom_field_values][52]"
            type="text" value="" /></span>
    })
  end
end
