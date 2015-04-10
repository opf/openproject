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

describe ProjectsController, type: :routing do

  describe 'index' do
    it { expect(get('/projects')).to route_to(controller: 'projects', action: 'index') }
    it { expect(get('/projects.atom')).to route_to(controller: 'projects', action: 'index', format: 'atom') }
    it { expect(get('/projects.xml')).to route_to(controller: 'projects', action: 'index', format: 'xml') }
  end

  describe 'show' do
    it { expect(get('/projects/1')).to route_to(controller: 'projects', action: 'show', id: '1') }
    it { expect(get('/projects/1.xml')).to route_to(controller: 'projects', action: 'show', id: '1', format: 'xml') }
    it { expect(get('/projects/test')).to route_to(controller: 'projects', action: 'show', id: 'test') }
  end

  describe 'new' do
    it { expect(get('/projects/new')).to route_to(controller: 'projects', action: 'new') }

  end

  describe 'create' do
    it { expect(post('/projects')).to route_to(controller: 'projects', action: 'create') }
    it { expect(post('/projects.xml')).to route_to(controller: 'projects', action: 'create', format: 'xml') }
  end

  describe 'update' do
    it { expect(put('/projects/123')).to route_to(controller: 'projects', action: 'update', id: '123') }
    it { expect(put('/projects/123.xml')).to route_to(controller: 'projects', action: 'update', id: '123', format: 'xml') }
  end

  describe 'destroy_info' do
    it { expect(get('/projects/123/destroy_info')).to route_to(controller: 'projects', action: 'destroy_info', id: '123') }
  end

  describe 'delete' do
    it { expect(delete('/projects/123')).to route_to(controller: 'projects', action: 'destroy', id: '123') }
    it { expect(delete('/projects/123.xml')).to route_to(controller: 'projects', action: 'destroy', id: '123', format: 'xml') }
  end

  describe 'miscellanous' do
    it { expect(get('/projects/123/settings')).to route_to(controller: 'projects',      action: 'settings',     id: '123') }
    it { expect(get('/projects/123/settings/members')).to route_to(controller: 'projects',      action: 'settings',     id: '123', tab: 'members') }
    it { expect(put('projects/123/modules')).to route_to(controller: 'projects',      action: 'modules',      id: '123') }
    it { expect(put('projects/123/archive')).to route_to(controller: 'projects',      action: 'archive',      id: '123') }
    it { expect(put('projects/123/unarchive')).to route_to(controller: 'projects',      action: 'unarchive',    id: '123') }
    it { expect(get('projects/123/copy_project_from_settings')).to route_to(controller: 'copy_projects', action: 'copy_project', id: '123', coming_from: 'settings') }
    it { expect(post('projects/123/copy')).to route_to(controller: 'copy_projects', action: 'copy',         id: '123') }
  end

  describe 'types' do
    it do
      expect(post('/projects/types/123')).to route_to(controller: 'projects',
                                                      action: 'types',
                                                      id: '123')
    end
  end
end
