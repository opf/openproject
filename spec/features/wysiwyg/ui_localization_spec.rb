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

RSpec.describe "WYSIWYG UI localization", :js do
  let(:user) { create(:admin, language:) }
  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:editor) { Components::WysiwygEditor.new }

  let(:wiki_page) do
    page = build(:wiki_page)
    page.text = <<~MARKDOWN
      paragraph

      # h1
    MARKDOWN

    page
  end

  before do
    login_as(user)
    project.wiki.pages << wiki_page
    project.wiki.save!

    visit edit_project_wiki_path(project, wiki_page.slug)
  end

  context "with german locale" do
    let(:language) { :de }

    it "renders the UI in German" do
      expect(page).to have_css(".ck-button__label", text: "Absatz")
    end
  end

  context "with english locale" do
    let(:language) { :en }

    it "renders the UI in English" do
      expect(page).to have_css(".ck-button__label", text: "Paragraph")
    end
  end
end
