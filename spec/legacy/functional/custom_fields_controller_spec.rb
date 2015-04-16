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

require 'legacy_spec_helper'
require 'custom_fields_controller'

describe CustomFieldsController, type: :controller do
  render_views

  fixtures :all

  before do
    session[:user_id] = 1
  end

  it 'should get new issue custom field' do
    get :new, type: 'WorkPackageCustomField'
    assert_response :success
    assert_template 'new'
    assert_tag :select,
               attributes: { name: 'custom_field[field_format]' },
               child: {
                 tag: 'option',
                 attributes: { value: 'user' },
                 content: 'User'
               }
    assert_tag :select,
               attributes: { name: 'custom_field[field_format]' },
               child: {
                 tag: 'option',
                 attributes: { value: 'version' },
                 content: 'Version'
               }
  end

  it 'should get new with invalid custom field class should redirect to list' do
    get :new, type: 'UnknownCustomField'
    assert_redirected_to '/custom_fields'
  end

  it 'should post new list custom field' do
    assert_difference 'CustomField.count' do
      post :create, type: 'WorkPackageCustomField',
                    custom_field: { name: 'test_post_new_list',
                                    default_value: '',
                                    min_length: '0',
                                    searchable: '0',
                                    regexp: '',
                                    is_for_all: '1',
                                    possible_values: "0.1\n0.2\n",
                                    max_length: '0',
                                    is_filter: '0',
                                    is_required: '0',
                                    field_format: 'list',
                                    type_ids: ['1', ''] }
    end
    assert_redirected_to '/custom_fields?tab=WorkPackageCustomField'
    field = WorkPackageCustomField.find_by_name('test_post_new_list')
    assert_not_nil field
    assert_equal ['0.1', '0.2'], field.possible_values
    assert_equal 1, field.types.size
  end
end
