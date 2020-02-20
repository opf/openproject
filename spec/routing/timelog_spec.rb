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

describe TimelogController, type: :routing do
  it 'connects GET /time_entries to timelog#index' do
    expect(get('/time_entries')).to route_to(controller: 'timelog',
                                             action: 'index')
  end

  it {
    expect(get('/time_entries.csv')).to route_to(controller: 'timelog',
                                                 action: 'index',
                                                 format: 'csv')
  }

  it {
    expect(get('/time_entries.atom')).to route_to(controller: 'timelog',
                                                  action: 'index',
                                                  format: 'atom')
  }

  it {
    is_expected.to route(:get, '/time_entries/new').to(controller: 'timelog',
                                                       action: 'new')
  }

  it {
    is_expected.to route(:get, '/time_entries/22/edit').to(controller: 'timelog',
                                                           action: 'edit',
                                                           id: '22')
  }

  it {
    is_expected.to route(:post, '/time_entries').to(controller: 'timelog',
                                                    action: 'create')
  }

  it {
    is_expected.to route(:put, '/time_entries/22').to(controller: 'timelog',
                                                      action: 'update',
                                                      id: '22')
  }

  it {
    is_expected.to route(:delete, '/time_entries/55').to(controller: 'timelog',
                                                         action: 'destroy',
                                                         id: '55')
  }

  context 'reports' do
    it {
      is_expected.to route(:get, '/time_entries/report').to(controller: 'time_entries/reports',
                                                            action: 'show')
    }
  end

  context 'work package scoped' do
    it 'should connect GET /work_packages/:work_package_id/time_entries/new to timelog#new' do
      expect(get('/work_packages/1/time_entries/new')).to route_to(controller: 'timelog',
                                                                   action: 'new',
                                                                   work_package_id: '1')
    end
  end

  context 'project scoped' do
    it 'connects GET /projects/:id/time_entries to timelog#index' do
      expect(get('/projects/1/time_entries')).to route_to(controller: 'timelog',
                                                          action: 'index',
                                                          project_id: '1')
    end

    it {
      expect(get('/projects/567/time_entries.csv')).to route_to(controller: 'timelog',
                                                                action: 'index',
                                                                project_id: '567',
                                                                format: 'csv')
    }

    it {
      expect(get('/projects/567/time_entries.atom')).to route_to(controller: 'timelog',
                                                                 action: 'index',
                                                                 project_id: '567',
                                                                 format: 'atom')
    }

    it {
      is_expected.to route(:get, '/projects/567/time_entries/new').to(controller: 'timelog',
                                                                      action: 'new',
                                                                      project_id: '567')
    }

    it {
      is_expected.to route(:get, '/projects/567/time_entries/22/edit').to(controller: 'timelog',
                                                                          action: 'edit',
                                                                          id: '22',
                                                                          project_id: '567')
    }

    it {
      is_expected.to route(:post, '/projects/567/time_entries').to(controller: 'timelog',
                                                                   action: 'create',
                                                                   project_id: '567')
    }

    it {
      is_expected.to route(:put, '/projects/567/time_entries/22').to(controller: 'timelog',
                                                                     action: 'update',
                                                                     id: '22',
                                                                     project_id: '567')
    }

    it {
      is_expected.to route(:delete, '/projects/567/time_entries/55').to(controller: 'timelog',
                                                                        action: 'destroy',
                                                                        id: '55',
                                                                        project_id: '567')
    }

    context 'reports' do
      it {
        is_expected.to route(:get, '/projects/567/time_entries/report').to(controller: 'time_entries/reports',
                                                                           action: 'show',
                                                                           project_id: '567')
      }

      it {
        expect(get('/projects/567/time_entries/report.csv')).to route_to(controller: 'time_entries/reports',
                                                                         action: 'show',
                                                                         project_id: '567',
                                                                         format: 'csv')
      }
    end
  end
end
