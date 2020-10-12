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

require_relative '../support/pages/dashboard'

describe 'Modifying a dashboard which already has widgets for which permissions are lacking', type: :feature, js: true do
  let!(:project) do
    FactoryBot.create :project
  end

  let(:permissions) do
    %i[view_dashboards
       manage_dashboards]
  end

  let(:user) do
    FactoryBot.create(:user, member_in_project: project, member_with_permissions: permissions)
  end
  let!(:dashboard) do
    FactoryBot.create(:dashboard_with_table, project: project)
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end
  let!(:news) do
    FactoryBot.create :news,
                      project: project
  end

  before do
    login_as user

    dashboard_page.visit!
  end

  it 'can add and modify widgets' do
    dashboard_page.add_widget(dashboard.row_count, dashboard.column_count, :row, "News")

    sleep(0.1)

    news_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)')

    within news_widget.area do
      expect(page)
        .to have_content(news.title)
    end

    visit root_path

    dashboard_page.visit!

    news_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)')

    within news_widget.area do
      expect(page)
        .to have_content(news.title)
    end

    news_widget.remove

    visit root_path

    dashboard_page.visit!

    expect(page)
      .to have_no_selector('.grid--area.-widgeted:nth-of-type(2)')
  end
end
