#-- encoding: UTF-8

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

describe 'Wysiwyg include wiki page spec',
         type: :feature, js: true do

  let(:project) {
    FactoryBot.create :project,
                      enabled_module_names: %w[wiki]
  }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_wiki_pages edit_wiki_pages]) }
  let(:user) {
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  }

  let(:wiki_page) {
    FactoryBot.create :wiki_page,
                      title: 'Test',
                      content: FactoryBot.build(:wiki_content, text: '# My page')
  }

  let(:included_page) {
    FactoryBot.create :wiki_page,
                      title: 'Included',
                      content: FactoryBot.build(:wiki_content, text: '# included page')
  }

  before do
    login_as(user)

    project.wiki.pages << wiki_page
    project.wiki.pages << included_page
    project.wiki.save!
  end


  let(:editor) { ::Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  describe 'in wikis' do
    describe 'creating a wiki page' do
      before do
        visit edit_project_wiki_path(project, :test)
      end

      it 'can add and edit an include page widget' do
        editor.in_editor do |container, editable|
          expect(editable).to have_selector('h1', text: 'My page')

          # strangely, we need visible: :all here
          editor.insert_macro 'Include content of another wiki page'

          expect(page).to have_selector('.op-modal--macro-modal')
          fill_in 'selected-page', with: 'included'

          # Cancel editing
          find('.op-modal--cancel-button').click
          expect(editable).to have_no_selector('.macro.-wiki_page_include')

          editor.insert_macro 'Include content of another wiki page'
          fill_in 'selected-page', with: 'included'

          # Save widget
          find('.op-modal--submit-button').click

          # Find widget, click to show toolbar
          placeholder = find('.macro.-wiki_page_include')

          # Placeholder states `included`
          expect(placeholder).to have_text('included')

          # Edit widget again
          placeholder.click
          page.find('.ck-balloon-panel .ck-button', visible: :all, text: 'Edit').click
          expect(page).to have_field('selected-page', with: 'included')
          find('.op-modal--cancel-button').click
        end

        # Save wiki page
        click_on 'Save'

        expect(page).to have_selector('.flash.notice')

        within('#content') do
          expect(page).to have_selector('section.macros--included-wiki-page')
          expect(page).to have_selector('section.macros--included-wiki-page h1', text: 'included page')
          expect(page).to have_selector('h1', text: 'My page')
        end
      end
    end
  end
end
