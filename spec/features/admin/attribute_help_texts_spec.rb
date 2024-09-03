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

RSpec.describe "Attribute help texts", :js, :with_cuprite do
  shared_let(:user_with_permission) { create(:user, global_permissions: [:edit_attribute_help_texts]) }

  let(:instance) { AttributeHelpText.last }
  let(:modal) { Components::AttributeHelpTextModal.new(instance) }
  let(:editor) { Components::WysiwygEditor.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:enterprise_token) { true }

  describe "Work package help texts" do
    before do
      login_as(user_with_permission)
      visit attribute_help_texts_path
    end

    # TODO: Migrate to cuprite when the `better_cuprite_billy` driver is added
    context "with direct uploads (Regression #34285)", :with_direct_uploads, with_cuprite: false do
      before do
        allow_any_instance_of(Attachment).to receive(:diskfile).and_return image_fixture
      end

      it "can upload an image" do
        page.find_test_selector("attribute-help-texts--create-button").click
        select "Status", from: "attribute_help_text_attribute_name"

        editor.set_markdown("My attribute help text")
        editor.drag_attachment image_fixture.path, "Image uploaded on creation"

        editor.attachments_list.expect_attached("image.png")
        click_button "Save"

        expect(page).to have_current_path attribute_help_texts_path(tab: :WorkPackage)

        expect(instance.help_text).to include "My attribute help text"
        expect(instance.help_text).to match /\/api\/v3\/attachments\/\d+\/content/
      end
    end

    context "with help texts allowed by the enterprise token" do
      it "allows CRUD to attribute help texts" do
        expect(page).to have_css(".generic-table--no-results-container")

        # Create help text
        # -> new
        page.find_test_selector("attribute-help-texts--create-button").click

        # Set attributes
        # -> create
        select "Status", from: "attribute_help_text_attribute_name"
        editor.set_markdown("My attribute help text")

        # Add an image
        # adding an image
        editor.drag_attachment image_fixture.path, "Image uploaded on creation"
        editor.attachments_list.expect_attached("image.png")
        click_button "Save"

        # Should now show on index for editing
        expect(page).to have_css(".attribute-help-text--entry td", text: "Status")
        expect(instance.attribute_scope).to eq "WorkPackage"
        expect(instance.attribute_name).to eq "status"
        expect(instance.help_text).to include "My attribute help text"
        expect(instance.help_text).to match /\/api\/v3\/attachments\/\d+\/content/

        # Open help text modal
        modal.open!
        expect(modal.modal_container).to have_text "My attribute help text"
        expect(modal.modal_container).to have_css("img")
        modal.expect_edit(editable: true)

        # Expect files section to be present
        expect(modal.modal_container).to have_css(".form--fieldset-legend", text: "ATTACHMENTS")
        expect(modal.modal_container).to have_test_selector("op-files-tab--file-list-item-title")

        modal.close!

        # -> edit
        SeleniumHubWaiter.wait
        find(".attribute-help-text--entry td a", text: "Status").click
        SeleniumHubWaiter.wait
        expect(page).to have_css("#attribute_help_text_attribute_name[disabled]")
        editor.set_markdown(" ")
        click_button "Save"

        # Handle errors
        expect(page).to have_css("#errorExplanation", text: "Help text can't be blank.")
        SeleniumHubWaiter.wait
        editor.set_markdown("New**help**text")
        click_button "Save"

        # On index again
        expect(page).to have_css(".attribute-help-text--entry td", text: "Status")
        instance.reload
        expect(instance.help_text).to eq "New**help**text"

        # Open help text modal
        modal.open!
        expect(modal.modal_container).to have_css("strong", text: "help")
        modal.expect_edit(editable: true)

        modal.close!
        expect(page).to have_css(".attribute-help-text--entry td", text: "Status")

        # Open again and edit this time
        modal.open!
        modal.edit_button.click
        expect(page).to have_css("#attribute_help_text_attribute_name[disabled]")
        visit attribute_help_texts_path

        # Create new, status is now blocked
        page.find_test_selector("attribute-help-texts--create-button").click
        expect(page).to have_css("#attribute_help_text_attribute_name option", text: "Assignee")
        expect(page).to have_no_css("#attribute_help_text_attribute_name option", text: "Status")
        visit attribute_help_texts_path

        # Destroy
        accept_alert do
          find(".attribute-help-text--entry .icon-delete").click
        end

        expect(page).to have_css(".generic-table--no-results-container")
        expect(AttributeHelpText.count).to be_zero
      end
    end
  end
end
