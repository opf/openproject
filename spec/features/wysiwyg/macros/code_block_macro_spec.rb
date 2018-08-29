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

describe 'Wysiwyg code block macro', type: :feature, js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w[wiki]) }
  let(:editor) { ::Components::WysiwygEditor.new }

  let(:snippet) {
    <<~RUBY
      def foobar
        'some ruby code'
      end
    RUBY
  }

  let(:expected) {
    <<~EXPECTED
      ```ruby
      #{snippet}
      ```
    EXPECTED
  }

  before do
    login_as(user)
  end

  describe 'in wikis' do
    describe 'creating a wiki page' do
      before do
        visit project_wiki_path(project, :wiki)
      end

      it 'can add and save multiple code blocks (Regression #28350)' do

        editor.in_editor do |container,|
          editor.set_markdown expected

          # Expect first macro saved to editor
          expect(container).to have_selector('.op-ckeditor--code-block', text: snippet)
          expect(container).to have_selector('.op-ckeditor--code-block-language', text: 'ruby')

          editor.set_markdown "#{expected}\n#{expected}"
          expect(container).to have_selector('.op-ckeditor--code-block', text: snippet, count: 2)
          expect(container).to have_selector('.op-ckeditor--code-block-language', text: 'ruby', count: 2)
        end

        click_on 'Save'
        expect(page).to have_selector('.flash.notice')

        # Expect output widget
        within('#content') do
          expect(page).to have_selector('pre.highlight-ruby', count: 2)
        end

        # Edit page again, expect widget
        click_on 'Edit'

        editor.in_editor do |container,|
          expect(container).to have_selector('.op-ckeditor--code-block', text: snippet, count: 2)
          expect(container).to have_selector('.op-ckeditor--code-block-language', text: 'ruby', count: 2)
        end
      end

      it 'can add and edit a code block widget' do
        editor.in_editor do |container,|
          editor.click_toolbar_button 'Insert code snippet'

          expect(page).to have_selector('.op-modal--macro-modal')

          # CM wraps an accessor to the editor instance on the outer container
          cm = page.find('.CodeMirror')
          page.execute_script('arguments[0].CodeMirror.setValue(arguments[1]);', cm.native, snippet)

          fill_in 'selected-language', with: 'ruby'

          # Expect some highlighting classes
          expect(page).to have_selector('.cm-keyword', text: 'def')
          expect(page).to have_selector('.cm-def', text: 'foobar')

          find('.op-modal--submit-button').click

          # Expect macro saved to editor
          expect(container).to have_selector('.op-ckeditor--code-block', text: snippet)
          expect(container).to have_selector('.op-ckeditor--code-block-language', text: 'ruby')
        end

        # Save wiki page
        click_on 'Save'

        expect(page).to have_selector('.flash.notice')

        wiki_page = project.wiki.find_page('wiki')
        text = wiki_page.content.text.gsub(/\r\n?/, "\n")
        expect(text.strip).to eq(expected.strip)

        # Expect output widget
        within('#content') do
          expect(page).to have_selector('pre.highlight-ruby')
        end

        # Edit page again, expect widget
        click_on 'Edit'

        editor.in_editor do |container,|
          expect(container).to have_selector('.op-ckeditor--code-block', text: snippet)
          expect(container).to have_selector('.op-ckeditor--code-block-language', text: 'ruby')

          widget = container.find('.op-ckeditor--code-block')
          page.driver.browser.mouse.double_click(widget.native)
          expect(page).to have_selector('.op-modal--macro-modal')

          expect(page).to have_selector('.op-ckeditor--code-block-language', text: 'ruby')
          expect(page).to have_selector('.cm-keyword', text: 'def')
          expect(page).to have_selector('.cm-def', text: 'foobar')
        end
      end
    end
  end
end
