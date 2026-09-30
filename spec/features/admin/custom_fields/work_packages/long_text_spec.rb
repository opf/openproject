# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "custom fields", :js do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::Index.new }
  let(:editor) { Components::WysiwygEditor.new "#custom_field_form" }
  let(:type) { create(:type_task) }
  let!(:project) { create(:project, enabled_module_names: %i[work_package_tracking], types: [type]) }

  let(:wp_page) { Pages::FullWorkPackageCreate.new project: }

  let(:default_text) do
    <<~MARKDOWN
      # This is an exemplary test

      **Foo bar**

    MARKDOWN
  end

  current_user { user }

  before do
    cf_page.visit!
  end

  describe "creating a new long text custom field" do
    it "creates a new bool custom field" do
      cf_page.click_to_create_new_custom_field("Long text")

      cf_page.set_name "New Field"

      editor.set_markdown default_text

      cf_page.set_all_projects true
      click_on "Save"

      cf_page.expect_and_dismiss_flash(message: "Successful creation.")
      expect(page).to have_text("New Field")

      cf = CustomField.last
      expect(cf.field_format).to eq "text"

      # textareas get carriage returns entered
      expect(cf.default_value.gsub("\r\n", "\n").strip).to eq default_text.strip

      type.default_variant.custom_field_ids |= [cf.id]
      type.save!

      wp_page.visit!
      wp_editor = TextEditorField.new(page, "description", selector: ".inline-edit--container.customField#{cf.id}")
      wp_editor.expect_active!

      wp_editor.ckeditor.in_editor do |container, _|
        expect(container).to have_css("h1", text: "This is an exemplary test")
        expect(container).to have_css("strong", text: "Foo bar")
      end
    end
  end
end
