#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Attribute help texts', js: true do
  shared_let(:admin) { FactoryBot.create :admin }

  let(:instance) { AttributeHelpText.last }
  let(:modal) { Components::AttributeHelpTextModal.new(instance) }
  let(:editor) { Components::WysiwygEditor.new }
  let(:image_fixture) { UploadedFile.load_from('spec/fixtures/files/image.png') }
  let(:relation_columns_allowed) { true }

  describe 'Work package help texts' do
    before do
      with_enterprise_token(relation_columns_allowed ? :attribute_help_texts : nil)

      login_as(admin)
      visit attribute_help_texts_path
    end

    context 'with direct uploads (Regression #34285)', with_direct_uploads: true do
      before do
        allow_any_instance_of(Attachment).to receive(:diskfile).and_return image_fixture
      end

      it 'can upload an image' do
        page.find('.attribute-help-texts--create-button').click
        select 'Status', from: 'attribute_help_text_attribute_name'

        editor.set_markdown('My attribute help text')
        editor.drag_attachment image_fixture.path, 'Image uploaded on creation'

        expect(page).to have_selector('attachment-list-item', text: 'image.png')
        click_button 'Save'

        expect(instance.help_text).to include 'My attribute help text'
        expect(instance.help_text).to match /\/api\/v3\/attachments\/\d+\/content/
      end
    end

    context 'with help texts allowed by the enterprise token' do
      it 'allows CRUD to attribute help texts' do
        expect(page).to have_selector('.generic-table--no-results-container')

        # Create help text
        # -> new
        page.find('.attribute-help-texts--create-button').click

        # Set attributes
        # -> create
        select 'Status', from: 'attribute_help_text_attribute_name'
        editor.set_markdown('My attribute help text')

        # Add an image
        # adding an image
        editor.drag_attachment image_fixture.path, 'Image uploaded on creation'
        expect(page).to have_selector('attachment-list-item', text: 'image.png')
        click_button 'Save'

        # Should now show on index for editing
        expect(page).to have_selector('.attribute-help-text--entry td', text: 'Status')
        expect(instance.attribute_scope).to eq 'WorkPackage'
        expect(instance.attribute_name).to eq 'status'
        expect(instance.help_text).to include 'My attribute help text'
        expect(instance.help_text).to match /\/api\/v3\/attachments\/\d+\/content/

        # Open help text modal
        modal.open!
        expect(modal.modal_container).to have_text 'My attribute help text'
        expect(modal.modal_container).to have_selector('img')
        modal.expect_edit(admin: true)

        # Expect files section to be present
        expect(modal.modal_container).to have_selector('.form--fieldset-legend', text: 'FILES')
        expect(modal.modal_container).to have_selector('.work-package--attachments--filename')

        modal.close!

        # -> edit
        SeleniumHubWaiter.wait
        page.find('.attribute-help-text--entry td a', text: 'Status').click
        SeleniumHubWaiter.wait
        expect(page).to have_selector('#attribute_help_text_attribute_name[disabled]')
        editor.set_markdown(' ')
        click_button 'Save'

        # Handle errors
        expect(page).to have_selector('#errorExplanation', text: "Help text can't be blank.")
        SeleniumHubWaiter.wait
        editor.set_markdown('New**help**text')
        click_button 'Save'

        # On index again
        expect(page).to have_selector('.attribute-help-text--entry td', text: 'Status')
        instance.reload
        expect(instance.help_text).to eq 'New**help**text'

        # Open help text modal
        modal.open!
        expect(modal.modal_container).to have_selector('strong', text: 'help')
        modal.expect_edit(admin: true)

        modal.close!
        expect(page).to have_selector('.attribute-help-text--entry td', text: 'Status')

        # Open again and edit this time
        modal.open!
        modal.edit_button.click
        expect(page).to have_selector('#attribute_help_text_attribute_name[disabled]')
        visit attribute_help_texts_path

        # Create new, status is now blocked
        page.find('.attribute-help-texts--create-button').click
        expect(page).to have_selector('#attribute_help_text_attribute_name option', text: 'Assignee')
        expect(page).to have_no_selector('#attribute_help_text_attribute_name option', text: 'Status')
        visit attribute_help_texts_path

        # Destroy
        page.find('.attribute-help-text--entry .icon-delete').click
        page.driver.browser.switch_to.alert.accept

        expect(page).to have_selector('.generic-table--no-results-container')
        expect(AttributeHelpText.count).to be_zero
      end
    end

    context 'with help texts disallowed by the enterprise token' do
      let(:relation_columns_allowed) { false }

      it 'hides CRUD to attribute help texts' do
        expect(page)
          .to have_selector(".errorExplanation",
                            text: "The page you were trying to access doesn't exist or has been removed.")
      end
    end
  end
end
