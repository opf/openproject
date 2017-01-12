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

describe TimelinesController, type: :routing do
  it 'connects GET /projects/:project_id/timelines to timelines#index' do
    expect(get('/projects/1/timelines'))
      .to route_to(controller: 'timelines',
                   action: 'index',
                   project_id: '1')
  end

  it 'connects GET /projects/:project_id/timelines/:id ' +
     'to timelines#show' do
    expect(get('/projects/1/timelines/2'))
      .to route_to(controller: 'timelines',
                   action: 'show',
                   project_id: '1',
                   id: '2')
  end

  it 'connects GET /projects/:project_id/timelines/new ' +
     'to timelines#new' do
    expect(get('/projects/1/timelines/new'))
      .to route_to(controller: 'timelines',
                   action: 'new',
                   project_id: '1')
  end

  it 'connects GET /projects/:project_id/timelines/:id/edit ' +
     'to timelines#edit' do
    expect(get('/projects/1/timelines/2/edit'))
      .to route_to(controller: 'timelines',
                   action: 'edit',
                   project_id: '1',
                   id: '2')
  end

  it 'connects PUT /projects/:project_id/timelines/:id ' +
     'to timelines#update' do
    expect(put('/projects/1/timelines/2'))
      .to route_to(controller: 'timelines',
                   action: 'update',
                   project_id: '1',
                   id: '2')
  end

  it 'connects POST /projects/:project_id/timelines ' +
     'to timelines#create' do
    expect(post('/projects/1/timelines'))
      .to route_to(controller: 'timelines',
                   action: 'create',
                   project_id: '1')
  end

  it 'connects GET /projects/:project_id/timelines/:id/confirm_destroy ' +
     'to timelines#confirm_destroy' do
    expect(get('/projects/1/timelines/2/confirm_destroy'))
      .to route_to(controller: 'timelines',
                   action: 'confirm_destroy',
                   project_id: '1',
                   id: '2')
  end

  it 'connects DELETE /projects/:project_id/timelines/:id ' +
     'to timelines#destroy' do
    expect(delete('/projects/1/timelines/2'))
      .to route_to(controller: 'timelines',
                   action: 'destroy',
                   project_id: '1',
                   id: '2')
  end
end
