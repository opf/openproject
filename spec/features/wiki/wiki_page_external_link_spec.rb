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

RSpec.describe "Wiki page external link", :js do
  shared_let(:admin) { create(:admin) }
  current_user { admin }

  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let!(:wiki_page) do
    create(:wiki_page,
           wiki: project.wiki,
           author: admin,
           title: "Wiki Page No. 55",
           text: 'A link to <a href="http://0.0.0.0:3001/">OpenProject</a>.')
  end

  it "opens that link in a new window or tab" do
    visit project_wiki_path(project, wiki_page)

    link = page.find('a[href^="http://0.0.0.0:3001/"]')
    new_window = window_opened_by { link.click }
    within_window new_window do
      expect(page.current_url).to start_with "http://0.0.0.0:3001/"
    end
    new_window.close
  end

  context "when the link contains an invalid url" do
    before do
      wiki_page.update(text: 'A link to <a href="https:///">OpenProject</a>.')
    end

    it "does not opens that link in a new window or tab" do
      visit project_wiki_path(project, wiki_page)

      link = page.find('a[href^="https:///"]')
      expect do
        window_opened_by { link.click }
      end.to raise_error Capybara::WindowError, /window_opened_by opened 0 windows instead of 1/
    end
  end
end
