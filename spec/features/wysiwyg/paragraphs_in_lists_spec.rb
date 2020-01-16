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

describe 'Wysiwyg paragraphs in lists behavior (Regression #28765)',
         type: :feature, js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w[wiki]) }
  let(:editor) { ::Components::WysiwygEditor.new }

  let(:wiki_page) {
    page = FactoryBot.build :wiki_page_with_content
    page.content.text = <<~MARKDOWN
      1. Step 1
         *Expected Results:* Expected 1

      2. Step 2
         *Expected Results:* Expected 2

      3. Step 3
         *Expected Results:* Expected 3
    MARKDOWN

    page
  }

  before do
    login_as(user)
    project.wiki.pages << wiki_page
    project.wiki.save!

    visit edit_project_wiki_path(project, wiki_page.slug)
  end

  it 'shows the list correctly' do
    editor.in_editor do |container, editable|
      expect(editable).to have_selector('ol li', count: 3)
      expect(editable).to have_no_selector('ol li p')
    end
  end
end
