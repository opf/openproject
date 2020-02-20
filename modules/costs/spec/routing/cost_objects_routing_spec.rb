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

describe CostObjectsController, type: :routing do
  describe 'routing' do
    it {
      expect(get('/projects/blubs/cost_objects/new')).to route_to(controller: 'cost_objects',
                                                                  action: 'new',
                                                                  project_id: 'blubs')
    }
    it {
      expect(post('/projects/blubs/cost_objects')).to route_to(controller: 'cost_objects',
                                                               action: 'create',
                                                               project_id: 'blubs')
    }
    it {
      expect(get('/projects/blubs/cost_objects')).to route_to(controller: 'cost_objects',
                                                              action: 'index',
                                                              project_id: 'blubs')
    }
    it {
      expect(get('/cost_objects/5')).to route_to(controller: 'cost_objects',
                                                 action: 'show',
                                                 id: '5')
    }
    it {
      expect(put('/cost_objects/5')).to route_to(controller: 'cost_objects',
                                                 action: 'update',
                                                 id: '5')
    }
    it {
      expect(delete('/cost_objects/5')).to route_to(controller: 'cost_objects',
                                                    action: 'destroy',
                                                    id: '5')
    }
    it {
      expect(post('/projects/42/cost_objects/update_material_budget_item')).to route_to(controller: 'cost_objects',
                                                                                        action: 'update_material_budget_item',
                                                                                        project_id: '42')
    }
    it {
      expect(post('/projects/42/cost_objects/update_labor_budget_item')).to route_to(controller: 'cost_objects',
                                                                                     action: 'update_labor_budget_item',
                                                                                     project_id: '42')
    }
    it {
      expect(get('/cost_objects/5/copy')).to route_to(controller: 'cost_objects',
                                                      action: 'copy',
                                                      id: '5')
    }
  end
end
