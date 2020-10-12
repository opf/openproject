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

describe CategoriesController, type: :routing do
  it 'should connect GET /projects/test/categories/new to categories#new' do
    expect(get('/projects/test/categories/new')).to route_to(controller: 'categories',
                                                             action: 'new',
                                                             project_id: 'test')
  end

  it 'should connect POST /projects/test/categories to categories#create' do
    expect(post('/projects/test/categories')).to route_to(controller: 'categories',
                                                          action: 'create',
                                                          project_id: 'test')
  end

  it 'should connect GET /categories/5/edit to categories#edit' do
    expect(get('/categories/5/edit')).to route_to(controller: 'categories',
                                                  action: 'edit',
                                                  id: '5')
  end

  it 'should connect PUT /categories/5 to categories#update' do
    expect(put('/categories/5')).to route_to(controller: 'categories',
                                             action: 'update',
                                             id: '5')
  end

  it 'should connect DELETE /categories/5 to categories#delete' do
    expect(delete('/categories/5')).to route_to(controller: 'categories',
                                                action: 'destroy',
                                                id: '5')
  end
end
