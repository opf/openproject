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

describe WikiController, type: :routing do
  describe 'routing' do
    it {
      is_expected.to route(:get, '/projects/567/wiki').to(controller: 'wiki',
                                                          action: 'show',
                                                          project_id: '567')
    }

    it 'should connect GET /projects/:project_id/wiki/:name (without format) to wiki/show' do
      expect(get('/projects/abc/wiki/blubs')).to route_to(controller: 'wiki',
                                                          action: 'show',
                                                          project_id: 'abc',
                                                          id: 'blubs')
    end

    it 'should connect GET /projects/:project_id/wiki/:name (with a dot in it) to wiki/show' do
      expect(get('/projects/abc/wiki/blubs.blubs')).to route_to(controller: 'wiki',
                                                                action: 'show',
                                                                project_id: 'abc',
                                                                id: 'blubs.blubs')
    end

    it 'should connect GET /projects/:project_id/wiki/:name.html to wiki/show' do
      expect(get('/projects/abc/wiki/blubs.markdown')).to route_to(controller: 'wiki',
                                                                   action: 'show',
                                                                   project_id: 'abc',
                                                                   id: 'blubs',
                                                                   format: 'markdown')
    end

    it 'should connect GET /projects/:project_id/wiki/new to wiki/new' do
      expect(get('/projects/abc/wiki/new')).to route_to(controller: 'wiki',
                                                        action: 'new',
                                                        project_id: 'abc')
    end

    it 'should connect GET /projects/:project_id/wiki/:id/new to wiki/new_child' do
      expect(get('/projects/abc/wiki/def/new')).to route_to(controller: 'wiki',
                                                            action: 'new_child',
                                                            project_id: 'abc',
                                                            id: 'def')
    end

    it 'should connect POST /projects/:project_id/wiki/new to wiki/create' do
      expect(post('/projects/abc/wiki/new')).to route_to(controller: 'wiki',
                                                         action: 'create',
                                                         project_id: 'abc')
    end

    it {
      is_expected.to route(:get, '/projects/567/wiki/my_page/edit').to(controller: 'wiki',
                                                                       action: 'edit',
                                                                       project_id: '567',
                                                                       id: 'my_page')
    }

    it do
      expect(get('/projects/abc/wiki/abc_wiki?version=3')).to route_to(controller: 'wiki',
                                                                       action: 'show',
                                                                       project_id: 'abc',
                                                                       id: 'abc_wiki',
                                                                       version: '3')
    end

    it 'should connect GET /projects/:project_id/wiki/:id/parent_page to wiki/edit_parent_page' do
      expect(get('/projects/abc/wiki/abc_wiki/parent_page'))
        .to route_to(controller: 'wiki',
                     action: 'edit_parent_page',
                     project_id: 'abc',
                     id: 'abc_wiki')
    end

    it 'should connect PATCH /projects/:project_id/wiki/:id/parent_page to wiki/update_parent_page' do
      expect(patch('/projects/abc/wiki/abc_wiki/parent_page'))
        .to route_to(controller: 'wiki',
                     action: 'update_parent_page',
                     project_id: 'abc',
                     id: 'abc_wiki')
    end

    it 'should connect GET /projects/:project_id/wiki/:id/toc to wiki#index' do
      expect(get('/projects/abc/wiki/blubs/toc')).to route_to(controller: 'wiki',
                                                              action: 'index',
                                                              project_id: 'abc',
                                                              id: 'blubs')
    end

    it {
      is_expected.to route(:get, '/projects/1/wiki/CookBook_documentation/history').to(controller: 'wiki',
                                                                                       action: 'history',
                                                                                       project_id: '1',
                                                                                       id: 'CookBook_documentation')
    }
    it {
      is_expected.to route(:get, '/projects/1/wiki/CookBook_documentation/diff').to(controller: 'wiki',
                                                                                    action: 'diff',
                                                                                    project_id: '1',
                                                                                    id: 'CookBook_documentation')
    }

    it {
      is_expected.to route(:get, '/projects/1/wiki/CookBook_documentation/diff/2').to(controller: 'wiki',
                                                                                      action: 'diff',
                                                                                      project_id: '1',
                                                                                      id: 'CookBook_documentation',
                                                                                      version: '2')
    }

    it {
      is_expected.to route(:get, '/projects/1/wiki/CookBook_documentation/diff/2/vs/1').to(controller: 'wiki',
                                                                                           action: 'diff',
                                                                                           project_id: '1',
                                                                                           id: 'CookBook_documentation',
                                                                                           version: '2',
                                                                                           version_from: '1')
    }

    it {
      is_expected.to route(:get, '/projects/1/wiki/CookBook_documentation/annotate/2').to(controller: 'wiki',
                                                                                          action: 'annotate',
                                                                                          project_id: '1',
                                                                                          id: 'CookBook_documentation',
                                                                                          version: '2')
    }

    it {
      is_expected.to route(:get, '/projects/22/wiki/ladida/rename').to(controller: 'wiki',
                                                                       action: 'rename',
                                                                       project_id: '22',
                                                                       id: 'ladida')
    }

    it {
      is_expected.to route(:get, '/projects/567/wiki/index').to(controller: 'wiki',
                                                                action: 'index',
                                                                project_id: '567')
    }

    it {
      is_expected.to route(:get, '/projects/567/wiki/date_index').to(controller: 'wiki',
                                                                     action: 'date_index',
                                                                     project_id: '567')
    }

    it {
      is_expected.to route(:get, '/projects/567/wiki/export').to(controller: 'wiki',
                                                                 action: 'export',
                                                                 project_id: '567')
    }

    it {
      is_expected.to route(:patch, '/projects/22/wiki/ladida/rename').to(controller: 'wiki',
                                                                         action: 'rename',
                                                                         project_id: '22',
                                                                         id: 'ladida')
    }

    it {
      is_expected.to route(:post, '/projects/22/wiki/ladida/protect').to(controller: 'wiki',
                                                                         action: 'protect',
                                                                         project_id: '22',
                                                                         id: 'ladida')
    }

    it {
      is_expected.to route(:put, '/projects/567/wiki/my_page').to(controller: 'wiki',
                                                                  action: 'update',
                                                                  project_id: '567',
                                                                  id: 'my_page')
    }

    it {
      is_expected.to route(:delete, '/projects/22/wiki/ladida').to(controller: 'wiki',
                                                                   action: 'destroy',
                                                                   project_id: '22',
                                                                   id: 'ladida')
    }
  end
end
