#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe BoardsController, type: :routing do
  it {
    is_expected.to route(:get, '/projects/world_domination/boards').to(controller: 'boards',
                                                                       action: 'index',
                                                                       project_id: 'world_domination')
  }
  it {
    is_expected.to route(:get, '/projects/world_domination/boards/new').to(controller: 'boards',
                                                                           action: 'new',
                                                                           project_id: 'world_domination')
  }
  it {
    is_expected.to route(:post, '/projects/world_domination/boards').to(controller: 'boards',
                                                                        action: 'create',
                                                                        project_id: 'world_domination')
  }
  it {
    is_expected.to route(:get, '/projects/world_domination/boards/44').to(controller: 'boards',
                                                                          action: 'show',
                                                                          project_id: 'world_domination',
                                                                          id: '44')
  }
  it {
    expect(get('/projects/abc/boards/1.atom'))
      .to route_to(controller: 'boards',
                   action: 'show',
                   project_id: 'abc',
                   id: '1',
                   format: 'atom')
  }
  it {
    is_expected.to route(:get, '/projects/world_domination/boards/44/edit').to(controller: 'boards',
                                                                               action: 'edit',
                                                                               project_id: 'world_domination',
                                                                               id: '44')
  }
  it {
    is_expected.to route(:put, '/projects/world_domination/boards/44').to(controller: 'boards',
                                                                          action: 'update',
                                                                          project_id: 'world_domination',
                                                                          id: '44')
  }
  it {
    is_expected.to route(:delete, '/projects/world_domination/boards/44').to(controller: 'boards',
                                                                             action: 'destroy',
                                                                             project_id: 'world_domination',
                                                                             id: '44')
  }

  it 'should connect GET /projects/:project/boards/:board/move to boards#move' do
    expect(get('/projects/1/boards/1/move')).to route_to(controller: 'boards',
                                                         action: 'move',
                                                         project_id: '1',
                                                         id: '1')
  end

  it 'should connect POST /projects/:project/boards/:board/move to boards#move' do
    expect(post('/projects/1/boards/1/move')).to route_to(controller: 'boards',
                                                          action: 'move',
                                                          project_id: '1',
                                                          id: '1')
  end
end
