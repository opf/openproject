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

describe 'preview', type: :routing do
  it 'should connect POST /projects/:project_id/wiki/preview to wiki#preview' do
    expect(post('/projects/1/wiki/preview')).to route_to(controller: 'wiki',
                                                         action: 'preview',
                                                         project_id: '1')
  end

  it 'should connect POST /projects/:project_id/wiki/:id/preview to wiki#preview' do
    expect(post('/projects/1/wiki/1/preview')).to route_to(controller: 'wiki',
                                                           action: 'preview',
                                                           project_id: '1',
                                                           id: '1')
  end

  it 'should connect POST news/preview to news#preview' do
    expect(post('/news/preview')).to route_to(controller: 'news',
                                              action: 'preview')
  end

  it 'should connect POST /news/:id/preview to news#preview' do
    expect(post('/news/1/preview')).to route_to(controller: 'news',
                                                action: 'preview',
                                                id: '1')
  end

  it 'should connect POST /boards/:board_id/topics/preview to messages#preview' do
    expect(post('/boards/1/topics/preview')).to route_to(controller: 'messages',
                                                         action: 'preview',
                                                         board_id: '1')
  end

  it 'should connect POST /topics/:id/preview to messages#preview' do
    expect(post('/topics/1/preview')).to route_to(controller: 'messages',
                                                  action: 'preview',
                                                  id: '1')
  end

  it 'should connect POST /work_packages/preview to work_packages#preview' do
    expect(post('/work_packages/preview')).to route_to(controller: 'work_packages',
                                                       action: 'preview')
  end

  it 'should connect POST /work_packages/:id/preview to work_packages#preview' do
    expect(post('/work_packages/1/preview')).to route_to(controller: 'work_packages',
                                                         action: 'preview',
                                                         id: '1')
  end
end
