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

require_relative '../support/pages/dashboard'

describe 'Project status widget on dashboard', type: :feature, js: true do
  let!(:project) { FactoryBot.create :project, status: project_status }
  let!(:project_status) do
    FactoryBot.create :project_status
  end
  let(:permissions) do
    %i[view_dashboards manage_dashboards]
  end
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end

  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard.visit!
  end

  it 'can add the widget and see the status' do
    # within top-right area, add an additional widget
    dashboard.add_widget(1, 1, :within, 'Project status')

    status_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    within status_widget.area do
      expect(page)
        .to have_content project_status.explanation

      expect(page)
        .to have_content 'ON TRACK'
    end
  end
end
