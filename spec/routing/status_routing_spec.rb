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

describe StatusesController, type: :routing do

  describe 'index' do
    it { expect(get('/statuses')).to route_to(controller: 'statuses', action: 'index') }
  end

  describe 'new' do
    it { expect(get('/statuses/new')).to route_to(controller: 'statuses', action: 'new') }

  end

  describe 'create' do
    it { expect(post('/statuses')).to route_to(controller: 'statuses', action: 'create') }
  end

  describe 'update' do
    it { expect(put('/statuses/123')).to route_to(controller: 'statuses', action: 'update', id: '123') }
  end

  describe 'delete' do
    it { expect(delete('/statuses/123')).to route_to(controller: 'statuses', action: 'destroy', id: '123') }
  end

  describe 'update_work_package_done_ratio' do
    it do
      expect(post('/statuses/update_work_package_done_ratio')).to route_to(
        controller: 'statuses',
        action: 'update_work_package_done_ratio')
    end
  end
end
