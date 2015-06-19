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

describe WikiController, type: :routing do
  describe 'routing' do
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

    it do
      expect(get('/projects/abc/wiki/abc_wiki?version=3')).to route_to(
                 controller: 'wiki',
                 action: 'show',
                 project_id: 'abc',
                 id: 'abc_wiki')
    end
  end
end
