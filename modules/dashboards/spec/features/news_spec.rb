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

describe 'News widget on dashboard', type: :feature, js: true do
  let!(:project) { FactoryBot.create :project }
  let!(:other_project) { FactoryBot.create :project }
  let!(:visible_news) do
    FactoryBot.create :news,
                      project: project,
                      description: 'blubs'
  end
  let!(:invisible_news) do
    FactoryBot.create :news,
                      project: other_project
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i[view_news
                                      view_dashboards
                                      manage_dashboards])
  end
  let(:user) do
    FactoryBot.create(:user).tap do |u|
      FactoryBot.create(:member, project: project, roles: [role], user: u)
      FactoryBot.create(:member, project: other_project, roles: [role], user: u)
    end
  end

  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard.visit!
  end

  it 'can add the widget and see the visible news' do
    # within top-right area, add an additional widget
    dashboard.add_widget(1, 1, :within, 'News')

    news_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

    within news_widget.area do
      expect(page)
        .to have_content visible_news.title
      expect(page)
        .to have_content visible_news.author.name
      expect(page)
        .to have_content visible_news.project.name
      expect(page)
        .to have_content visible_news.created_at.strftime('%m/%d/%Y')

      expect(page)
        .to have_no_content invisible_news.title
    end
  end
end
