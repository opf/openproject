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

describe ProjectSettingsController, type: :routing do
  describe 'show' do
    it do
      expect(get('/projects/123/settings/info')).to route_to(
                                                      controller: 'project_settings', action: 'show', id: '123', tab: 'info'
                                                    )
    end

    it do
      expect(get('/projects/123/settings/modules')).to route_to(
                                                         controller: 'project_settings', action: 'show', id: '123', tab: 'modules'
                                                       )
    end

    it do
      expect(get('/projects/123/settings/members')).to route_to(
                                                         controller: 'project_settings', action: 'show', id: '123', tab: 'members'
                                                       )
    end

    it do
      expect(get('/projects/123/settings/custom_fields')).to route_to(
                                                               controller: 'project_settings', action: 'show', id: '123',
                                                               tab: 'custom_fields'
                                                             )
    end

    it do
      expect(get('/projects/123/settings/versions')).to route_to(
                                                          controller: 'project_settings', action: 'show', id: '123',
                                                          tab: 'versions'
                                                        )
    end

    it do
      expect(get('/projects/123/settings/categories')).to route_to(
                                                            controller: 'project_settings', action: 'show', id: '123', tab: 'categories'
                                                          )
    end

    it do
      expect(get('/projects/123/settings/repositories')).to route_to(
                                                              controller: 'project_settings', action: 'show', id: '123',
                                                              tab: 'repositories'
                                                            )
    end

    it do
      expect(get('/projects/123/settings/boards')).to route_to(
                                                        controller: 'project_settings', action: 'show', id: '123',
                                                        tab: 'boards'
                                                      )
    end

    it do
      expect(get('/projects/123/settings/activities')).to route_to(
                                                            controller: 'project_settings', action: 'show', id: '123',
                                                            tab: 'activities'
                                                          )
    end

    it do
      expect(get('/projects/123/settings/types')).to route_to(
                                                       controller: 'project_settings', action: 'show', id: '123',
                                                       tab: 'types'
                                                     )
    end
  end

  describe 'miscellaneous' do
    it do
      expect(get('/projects/123/settings')).to route_to(
        controller: 'project_settings', action: 'show', id: '123'
      )
    end
  end
end
