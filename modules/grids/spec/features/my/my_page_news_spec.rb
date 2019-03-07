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

describe 'My page news widget spec', type: :feature, js: true do
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
  let(:other_user) do
    FactoryBot.create(:user)
  end
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[])
  end
  let(:my_page) do
    Pages::My::Page.new
  end

  before do
    login_as user

    my_page.visit!
  end

  it 'can add the widget and see the visible news' do
    created_area = Components::Grids::GridArea.new('.grid--area', text: 'Work packages created by me')

    created_area.remove

    sleep(0.5)

    # within top-right area, add an additional widget
    my_page.add_widget(1, 3, 'News')

    document_area = Components::Grids::GridArea.new('.grid--area', text: 'News')
    document_area.expect_to_span(1, 3, 4, 5)

    document_area.resize_to(7, 4)

    expect(page)
      .to have_content visible_news.title
    expect(page)
      .to have_content visible_news.author.name
    expect(page)
      .to have_content visible_news.project.name
    expect(page)
      .to have_content visible_news.created_on.strftime('%m/%d/%Y')

    expect(page)
      .to have_no_content invisible_news.title
  end
end
