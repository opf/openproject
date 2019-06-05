#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'spec_helper'

describe MyProjectsOverviewsController, type: :routing do
  describe "routing" do
    describe "overview-page" do
      it {
        expect(get('/projects/test-project')).to route_to(controller: 'my_projects_overviews',
                                                          action: 'index',
                                                          id: 'test-project')
      }

      # make sure that the mappings are not greedy
      it {
        expect(get('/projects/new')).to route_to(controller: 'projects',
                                                 action: 'new')
      }

      it {
        expect(get('/projects/test-project/settings')).to route_to(controller: 'project_settings',
                                                                   action: 'show',
                                                                   id: 'test-project')
      }

    end


  end
end
