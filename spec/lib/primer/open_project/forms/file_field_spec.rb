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

RSpec.describe Primer::OpenProject::Forms::FileField, type: :forms do
  include_context "with rendered inline form"

  let(:model) { build_stubbed(:project) }
  let(:hidden_file_field) { "input[type=file][name='project[file]']" }

  def render_file_field(**)
    vc_render_inline_form do |form|
      form.file_field(name: :file, label: "Upload file", **)
    end
  end

  it "renders a hidden native file input" do
    render_file_field

    expect(page).to have_css(hidden_file_field, visible: :all)
  end

  it "scopes the file-field Stimulus controller over both the hidden input and the drop zone" do
    render_file_field

    controller_scope = page.find("[data-controller='file-field']", visible: :all)

    expect(controller_scope).to have_css("[data-file-field-target='file']", visible: :all)
    expect(controller_scope).to have_css("[data-file-field-target='dropBox']")
  end

  it "renders a dashed drop zone showing the label as placeholder text" do
    render_file_field

    expect(page).to have_button("Upload file", class: "FormControl-file-field-drop-zone")
  end

  it "renders the caption below the drop zone when given, via the shared FormControl layout" do
    render_file_field(caption: "PDF up to 10 MB")

    expect(page).to have_css(".FormControl > .FormControl-caption", text: "PDF up to 10 MB")
  end

  it "renders the description inside the drop zone, separately from the caption below it" do
    render_file_field(description: "PDF, DOCX up to 10 MB")

    expect(page).to have_css(
      "button.FormControl-file-field-drop-zone .FormControl-caption",
      text: "PDF, DOCX up to 10 MB"
    )
  end

  it "renders an accessible, visually hidden label associated with the hidden file input" do
    render_file_field

    label = page.find(".FormControl-label.sr-only", visible: :all)
    expect(label[:for]).to eq(page.find(hidden_file_field, visible: :all)[:id])
  end

  it "disables both the hidden input and the drop zone when disabled" do
    render_file_field(disabled: true)

    expect(page).to have_css("#{hidden_file_field}[disabled]", visible: :all)
    expect(page).to have_button("Upload file", class: "FormControl-file-field-drop-zone", disabled: true)
  end

  context "without auto_submit" do
    it "only wires the change action to fileChosen" do
      render_file_field

      field = page.find(hidden_file_field, visible: :all)
      expect(field["data-action"]).to eq("change->file-field#fileChosen")
    end
  end

  context "with auto_submit" do
    it "also wires the change action to auto-submit, so picking a file submits the form" do
      render_file_field(auto_submit: true)

      field = page.find(hidden_file_field, visible: :all)
      expect(field["data-action"]).to eq("change->file-field#fileChosen change->auto-submit#submit")
    end
  end

  context "without a preview_url" do
    it "does not mark the wrapper as having a preview, so the icon/label/caption stay visible" do
      render_file_field

      expect(page).to have_css("[data-controller='file-field']:not(.FormControl-file-field-wrap--has-preview)")
      expect(page.find("img.FormControl-file-field-preview", visible: :all)[:src]).to be_blank
    end
  end

  context "with a preview_url" do
    it "marks the wrapper as having a preview, hiding the icon/label/caption placeholder" do
      render_file_field(preview_url: "/uploads/logo.png")

      expect(page).to have_css("[data-controller='file-field'].FormControl-file-field-wrap--has-preview")
      preview = page.find("img.FormControl-file-field-preview")
      expect(preview[:src]).to eq("/uploads/logo.png")
    end

    it "adds the given preview_class alongside the component's own class" do
      render_file_field(preview_url: "/uploads/logo.png", preview_class: "custom-logo-preview")

      expect(page).to have_css("img.FormControl-file-field-preview.custom-logo-preview")
    end

    it "adds preview_data as data attributes on the preview image, alongside the component's own" do
      render_file_field(preview_url: "/uploads/logo.png", preview_data: { "color-mode": :light, "light-theme": :light })

      preview = page.find("img.FormControl-file-field-preview", visible: :all)
      expect(preview["data-file-field-target"]).to eq("preview")
      expect(preview["data-color-mode"]).to eq("light")
      expect(preview["data-light-theme"]).to eq("light")
    end
  end

  context "with a filename but no preview_url (e.g. a font, which cannot be previewed as an image)" do
    it "shows the filename instead of the label, without marking the wrapper as having a preview" do
      render_file_field(filename: "Regular.ttf")

      expect(page).to have_button("Regular.ttf", class: "FormControl-file-field-drop-zone")
      expect(page).to have_css("[data-controller='file-field']:not(.FormControl-file-field-wrap--has-preview)")
    end

    it "still resets to the label as the empty-state placeholder for a newly chosen file" do
      render_file_field(filename: "Regular.ttf", label: "Upload file")

      label = page.find("[data-file-field-target='filename']", visible: :all)
      expect(label[:"data-empty"]).to eq("Upload file")
    end
  end

  describe "the actions menu" do
    context "without a preview_url or filename" do
      it "does not render the menu, since there is nothing uploaded yet to act on" do
        render_file_field(delete_path: "/uploads/logo")

        expect(page).to have_no_css(".FormControl-file-field-menu", visible: :all)
      end
    end

    context "with a preview_url, when disabled" do
      it "does not render the menu, since the field cannot be acted on" do
        render_file_field(preview_url: "/uploads/logo.png", delete_path: "/uploads/logo", disabled: true)

        expect(page).to have_no_css(".FormControl-file-field-menu", visible: :all)
      end
    end

    context "with only a filename (no preview_url)" do
      it "renders the menu, since a file is already uploaded even though it cannot be previewed" do
        render_file_field(filename: "Regular.ttf", delete_path: "/uploads/font")

        expect(page).to have_css(".FormControl-file-field-menu", visible: :all)
      end
    end

    context "with a preview_url" do
      it "renders a Replace item that triggers the same action as clicking the drop zone" do
        render_file_field(preview_url: "/uploads/logo.png")

        expect(page).to have_css(
          ".FormControl-file-field-menu [data-action='click->file-field#openFilePicker']",
          text: "Replace",
          visible: :all
        )
      end

      context "without a delete_path" do
        it "does not render a Delete item" do
          render_file_field(preview_url: "/uploads/logo.png")

          expect(page).to have_no_css(".FormControl-file-field-menu a", text: "Delete", visible: :all)
        end
      end

      context "with a delete_path" do
        it "renders a Delete item with the translated label and given href" do
          render_file_field(preview_url: "/uploads/logo.png", delete_path: "/uploads/logo")

          link = page.find(".FormControl-file-field-menu a", text: "Delete", visible: :all)
          expect(link[:href]).to eq("/uploads/logo")
        end

        it "passes delete_button_arguments through to the Delete item" do
          render_file_field(
            preview_url: "/uploads/logo.png",
            delete_path: "/uploads/logo",
            delete_button_arguments: { data: { turbo_method: :delete, test_selector: "delete-logo" } }
          )

          link = page.find(".FormControl-file-field-menu a", text: "Delete", visible: :all)
          expect(link["data-turbo-method"]).to eq("delete")
          expect(link["data-test-selector"]).to eq("delete-logo")
        end
      end
    end
  end
end
