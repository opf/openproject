#-- encoding: UTF-8

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

describe 'Wysiwyg child pages spec',
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

  let(:parent_page) {
    FactoryBot.create :wiki_page,
                      title: 'Parent page',
                      content: FactoryBot.build(:wiki_content, text: '# parent page')
  }

  let(:child_page) {
    FactoryBot.create :wiki_page,
                      title: 'Child page',
                      content: FactoryBot.build(:wiki_content, text: '# child page')
  }

  before do
    login_as(user)

    project.wiki.pages << wiki_page
    project.wiki.pages << parent_page
    project.wiki.pages << child_page
    child_page.parent = parent_page
    child_page.save!
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

      it 'can add and edit an child pages widget' do
        editor.in_editor do |_container, editable|
          expect(editable).to have_selector('h1', text: 'My page')

          editor.insert_macro 'Links to child pages'

          # Find widget, click to show toolbar
          placeholder = find('.macro.-child_pages')

          # Placeholder states `this page` and no `Include parent`
          expect(placeholder).to have_text('this page')
          expect(placeholder).not_to have_text('Include parent')

          # Edit widget and cancel again
          placeholder.click
          page.find('.ck-balloon-panel .ck-button', visible: :all, text: 'Edit').click
          expect(page).to have_selector('.op-modal--macro-modal')
          expect(page).to have_field('selected-page', with: '')
          find('.op-modal--cancel-button').click

          # Edit widget and save
          placeholder.click
          page.find('.ck-balloon-panel .ck-button', visible: :all, text: 'Edit').click
          expect(page).to have_selector('.op-modal--macro-modal')
          fill_in 'selected-page', with: 'parent-page'

          # Save widget
          find('.op-modal--submit-button').click

          # Placeholder states `parent-page` and no `Include parent`
          expect(placeholder).to have_text('parent-page')
          expect(placeholder).not_to have_text('Include parent')
        end

        # Save wiki page
        click_on 'Save'

        expect(page).to have_selector('.flash.notice')

        within('#content') do
          expect(page).to have_selector('.pages-hierarchy')
          expect(page).to have_selector('.pages-hierarchy', text: 'Child page')
          expect(page).not_to have_selector('.pages-hierarchy', text: 'Parent page')
          expect(page).to have_selector('h1', text: 'My page')

          find('.toolbar .icon-edit').click
        end

        editor.in_editor do |_container, _editable|
          # Find widget, click to show toolbar
          placeholder = find('.macro.-child_pages')

          # Edit widget and save
          placeholder.click
          page.find('.ck-balloon-panel .ck-button', visible: :all, text: 'Edit').click
          expect(page).to have_selector('.op-modal--macro-modal')
          page.check 'include-parent'

          # Save widget
          find('.op-modal--submit-button').click

          # Placeholder states `parent-page` and `Include parent`
          expect(placeholder).to have_text('parent-page')
          expect(placeholder).to have_text('Include parent')
        end

        # Save wiki page
        click_on 'Save'

        expect(page).to have_selector('.flash.notice')

        within('#content') do
          expect(page).to have_selector('.pages-hierarchy')
          expect(page).to have_selector('.pages-hierarchy', text: 'Child page')
          expect(page).to have_selector('.pages-hierarchy', text: 'Parent page')
          expect(page).to have_selector('h1', text: 'My page')

          find('.toolbar .icon-edit').click
        end

      end
    end
  end
end
