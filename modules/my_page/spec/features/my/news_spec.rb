#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

require_relative "../../support/pages/my/page"

RSpec.describe "My page news widget spec", :js do
  let!(:project) { create(:project) }
  let!(:other_project) { create(:project) }
  let!(:visible_news) do
    create(:news,
           project:,
           description: "blubs")
  end
  let!(:invisible_news) do
    create(:news,
           project: other_project)
  end
  let(:other_user) do
    create(:user)
  end
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[] })
  end
  let(:my_page) do
    Pages::My::Page.new
  end

  before do
    login_as user

    my_page.visit!
  end

  it "can add the widget and see the visible news" do
    # No other widgets exist as the user lacks the permissions for the default widgets
    # add widget in top right corner
    my_page.add_widget(1, 1, :within, "News")

    news_area = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")
    news_area.expect_to_span(1, 1, 2, 2)

    expect(page)
      .to have_content visible_news.title
    expect(page)
      .to have_content visible_news.author.name
    expect(page)
      .to have_content visible_news.project.name
    expect(page)
      .to have_content visible_news.created_at.strftime("%m/%d/%Y")

    expect(page)
      .to have_no_content invisible_news.title
  end
end
