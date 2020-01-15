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

describe 'versions routing', type: :routing do
  it {
    is_expected.to route(:get, '/versions/1').to(controller: 'versions',
                                                 action: 'show',
                                                 id: '1')
  }

  it {
    is_expected.to route(:get, '/versions/1/edit').to(controller: 'versions',
                                                      action: 'edit',
                                                      id: '1')
  }

  it {
    is_expected.to route(:patch, '/versions/1').to(controller: 'versions',
                                                   action: 'update',
                                                   id: '1')
  }

  it {
    is_expected.to route(:delete, '/versions/1').to(controller: 'versions',
                                                    action: 'destroy',
                                                    id: '1')
  }

  it {
    is_expected.to route(:get, '/versions/1/status_by').to(controller: 'versions',
                                                           action: 'status_by',
                                                           id: '1')
  }

  context 'project scoped' do
    it {
      is_expected.to route(:get, '/projects/foo/versions/new').to(controller: 'versions',
                                                                  action: 'new',
                                                                  project_id: 'foo')
    }

    it {
      is_expected.to route(:post, '/projects/foo/versions').to(controller: 'versions',
                                                               action: 'create',
                                                               project_id: 'foo')
    }

    it {
      is_expected.to route(:put, '/projects/foo/versions/close_completed').to(controller: 'versions',
                                                                              action: 'close_completed',
                                                                              project_id: 'foo')
    }

    it {
      is_expected.to route(:get, '/projects/foo/roadmap').to(controller: 'versions',
                                                             action: 'index',
                                                             project_id: 'foo')
    }
  end
end
