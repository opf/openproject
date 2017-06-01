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

describe ProjectsController, type: :routing do
  describe 'index' do
    it do
      expect(get('/projects')).to route_to(
        controller: 'projects', action: 'index'
      )
    end

    it do
      expect(get('/projects.atom')).to route_to(
        controller: 'projects', action: 'index', format: 'atom'
      )
    end

    it do
      expect(get('/projects.xml')).to route_to(
        controller: 'projects', action: 'index', format: 'xml'
      )
    end
  end

  describe 'show' do
    it do
      expect(get('/projects/1')).to route_to(
        controller: 'projects', action: 'show', id: '1'
      )
    end

    it do
      expect(get('/projects/1.xml')).to route_to(
        controller: 'projects', action: 'show', id: '1', format: 'xml'
      )
    end

    it do
      expect(get('/projects/test')).to route_to(
        controller: 'projects', action: 'show', id: 'test'
      )
    end
  end

  describe 'new' do
    it do
      expect(get('/projects/new')).to route_to(
        controller: 'projects', action: 'new'
      )
    end
  end

  describe 'create' do
    it do
      expect(post('/projects')).to route_to(
        controller: 'projects', action: 'create'
      )
    end

    it do
      expect(post('/projects.xml')).to route_to(
        controller: 'projects', action: 'create', format: 'xml'
      )
    end
  end

  describe 'update' do
    it do
      expect(put('/projects/123')).to route_to(
        controller: 'projects', action: 'update', id: '123'
      )
    end

    it do
      expect(put('/projects/123.xml')).to route_to(
        controller: 'projects', action: 'update', id: '123', format: 'xml'
      )
    end
  end

  describe 'destroy_info' do
    it do
      expect(get('/projects/123/destroy_info')).to route_to(
        controller: 'projects', action: 'destroy_info', id: '123'
      )
    end
  end

  describe 'delete' do
    it do
      expect(delete('/projects/123')).to route_to(
        controller: 'projects', action: 'destroy', id: '123'
      )
    end

    it do
      expect(delete('/projects/123.xml')).to route_to(
        controller: 'projects', action: 'destroy', id: '123', format: 'xml'
      )
    end
  end

  describe 'miscellaneous' do
    it do
      expect(get('/projects/123/settings')).to route_to(
        controller: 'projects', action: 'settings', id: '123'
      )
    end

    it do
      expect(put('projects/123/modules')).to route_to(
        controller: 'projects', action: 'modules', id: '123'
      )
    end

    it do
      expect(put('projects/123/custom_fields')).to route_to(
        controller: 'projects', action: 'custom_fields', id: '123'
      )
    end

    it do
      expect(put('projects/123/archive')).to route_to(
        controller: 'projects', action: 'archive', id: '123'
      )
    end

    it do
      expect(put('projects/123/unarchive')).to route_to(
        controller: 'projects', action: 'unarchive', id: '123'
      )
    end

    it do
      expect(get('projects/123/copy_project_from_settings')).to route_to(
        controller: 'copy_projects', action: 'copy_project', id: '123',
        coming_from: 'settings'
      )
    end

    it do
      expect(post('projects/123/copy_from_settings')).to route_to(
        controller: 'copy_projects',
        action: 'copy',
        id: '123',
        coming_from: 'settings')
    end

    it do
      expect(post('projects/123/copy_from_admin')).to route_to(
        controller: 'copy_projects',
        action: 'copy',
        id: '123',
        coming_from: 'admin')
    end
  end

  describe 'settings' do
    it do
      expect(get('/projects/123/settings/info')).to route_to(
        controller: 'projects', action: 'settings', id: '123', tab: 'info'
      )
    end

    it do
      expect(get('/projects/123/settings/modules')).to route_to(
        controller: 'projects', action: 'settings', id: '123', tab: 'modules'
      )
    end

    it do
      expect(get('/projects/123/settings/members')).to route_to(
        controller: 'projects', action: 'settings', id: '123', tab: 'members'
      )
    end

    it do
      expect(get('/projects/123/settings/custom_fields')).to route_to(
        controller: 'projects', action: 'settings', id: '123',
        tab: 'custom_fields'
      )
    end

    it do
      expect(get('/projects/123/settings/versions')).to route_to(
        controller: 'projects', action: 'settings', id: '123',
        tab: 'versions'
      )
    end

    it do
      expect(get('/projects/123/settings/categories')).to route_to(
        controller: 'projects', action: 'settings', id: '123', tab: 'categories'
      )
    end

    it do
      expect(get('/projects/123/settings/repositories')).to route_to(
        controller: 'projects', action: 'settings', id: '123',
        tab: 'repositories'
      )
    end

    it do
      expect(get('/projects/123/settings/boards')).to route_to(
        controller: 'projects', action: 'settings', id: '123',
        tab: 'boards'
      )
    end

    it do
      expect(get('/projects/123/settings/activities')).to route_to(
        controller: 'projects', action: 'settings', id: '123',
        tab: 'activities'
      )
    end

    it do
      expect(get('/projects/123/settings/types')).to route_to(
        controller: 'projects', action: 'settings', id: '123',
        tab: 'types'
      )
    end
  end

  describe 'types' do
    it do
      expect(patch('/projects/123/types')).to route_to(
        controller: 'projects', action: 'types', id: '123'
      )
    end
  end
end
