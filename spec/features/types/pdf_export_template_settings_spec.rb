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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "type PDF export template settings", :js do
  shared_let(:admin) { create(:admin) }
  let(:type) { create(:type) }

  before do
    login_as(admin)
    visit edit_type_pdf_export_template_index_path(type)
  end

  it "edits, saves, and resets a template's settings, and can be left via Cancel" do
    click_link_or_button type.default_variant.pdf_export_templates.find("attributes").label

    fill_in "footer_text", with: "Custom footer text"
    select "Landscape", from: "page_orientation"
    click_link_or_button I18n.t(:button_save)

    expect(page).to have_current_path(edit_type_pdf_export_template_index_path(type))
    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(type.default_variant.reload.pdf_export_templates.settings_for("attributes"))
      .to include(footer_text: "Custom footer text", page_orientation: "landscape")

    click_link_or_button type.default_variant.pdf_export_templates.find("attributes").label
    expect(page).to have_field("footer_text", with: "Custom footer text")

    accept_confirm do
      click_link_or_button I18n.t("types.edit.export_configuration.templates.settings.reset_to_default")
    end

    expect(page).to have_current_path(edit_type_pdf_export_template_index_path(type))
    expect(type.default_variant.reload.pdf_export_templates.settings_for("attributes")).to eq({})
  end

  it "is reachable via the template name link, with the page title and " \
     "breadcrumb reflecting where it is" do
    template = type.default_variant.pdf_export_templates.find("attributes")
    click_link_or_button template.label

    expect(page).to have_current_path(
      edit_settings_type_pdf_export_template_path(type_id: type.id, id: "attributes")
    )
    expect(page).to have_css(
      ".PageHeader-title",
      text: I18n.t("types.edit.export_configuration.templates.settings.title", template: template.label)
    )
    within(".PageHeader-breadcrumbs") do
      expect(page).to have_link(I18n.t("types.edit.export_configuration.tab"))
      expect(page).to have_css("[aria-current='page']", text: template.label)
    end
  end

  it "keeps the table of contents enabled and the hyphenation language unset when saving " \
     "artefact settings that were never configured" do
    click_link_or_button type.default_variant.pdf_export_templates.find("artefact").label

    expect(page).to have_checked_field("toc_enabled")
    check "hyphenation_enabled_artefact"
    click_link_or_button I18n.t(:button_save)

    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(type.default_variant.reload.pdf_export_templates.settings_for("artefact"))
      .to eq(toc: "true", include_lifecycle: "true", include_budget: "true", hyphenation: "true")
  end

  it "leaves the settings unchanged when navigating away via Cancel" do
    click_link_or_button type.default_variant.pdf_export_templates.find("attributes").label

    fill_in "footer_text", with: "Unsaved footer text"
    click_link_or_button I18n.t(:button_cancel)

    expect(page).to have_current_path(edit_type_pdf_export_template_index_path(type))
    expect(type.default_variant.reload.pdf_export_templates.settings_for("attributes")).to eq({})
  end

  context "when the type links its PDF export config to a source type", with_flag: { type_variants: true } do
    let(:source) { create(:type) }

    before do
      source.default_variant.pdf_export_templates.update_settings("attributes", "footer_text" => "Source footer")
      source.default_variant.save!
      link_configuration(type, source:, aspect: TypeVariant::PDF_EXPORT)
      visit edit_type_pdf_export_template_index_path(type)
    end

    it "does not link the template label to its settings", :aggregate_failures do
      label = type.default_variant.pdf_export_templates.find("attributes").label

      expect(page).to have_text(label)
      expect(page).to have_no_link(label)
    end

    it "shows the inherited settings with disabled fields" do
      visit edit_settings_type_pdf_export_template_path(type_id: type.id, id: "attributes")

      expect(page).to have_field("footer_text", with: "Source footer", disabled: true)
      expect(page).to have_button(I18n.t(:button_save), disabled: true)
    end
  end
end
