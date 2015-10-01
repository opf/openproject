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

describe 'ApiTest: HttpBasicLoginTest', type: :request do
  fixtures :all

  before do
    Setting.rest_api_enabled = '1'
    Setting.login_required = '1'
  end

  after do
    Setting.rest_api_enabled = '0'
    Setting.login_required = '0'
  end

  context 'get /api/v2/projects/<ID>/planning_elements' do
    before do
      project = Project.find('onlinestore')
      EnabledModule.create(project: project, name: 'work_package_tracking')
    end

    context 'in :xml format' do
      should_allow_http_basic_auth_with_username_and_password(:get, '/api/v2/projects/onlinestore/planning_elements.xml')
    end

    context 'in :json format' do
      should_allow_http_basic_auth_with_username_and_password(:get, '/api/v2/projects/onlinestore/planning_elements.json')
    end
  end
end
