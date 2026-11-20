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

require "rails_helper"

RSpec.describe WorkPackageTypes::ExportTemplateListComponent, type: :component do
  include Rails.application.routes.url_helpers

  include_context "with variant scope"

  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:sortable_records) { variant.pdf_export_templates.list }

  subject(:rendered_component) { render_inline(described_class.new(variant:)) }

  it_behaves_like "rendering Box", row_count: 3

  def move_url
    id_placeholder = "__id__"
    move_type_pdf_export_template_path(type_id: type.id, id: id_placeholder).sub(id_placeholder, "{id}")
  end

  # The move URL is scoped by the variant's type id, so it cannot be a fixed
  # string the way the other sortable-lists consumers' URLs are.
  it "wires #work-package-types-export-template-list-component as the sortable-lists root" do
    expect(rendered_component).to have_css("#work-package-types-export-template-list-component") do |root|
      expect(root["data-controller"]).to eq("sortable-lists")
      expect(root["data-sortable-lists-move-url-template-value"]).to eq(move_url)
      expect(root["data-sortable-lists-sortable-lists--list-outlet"])
        .to eq("#work-package-types-export-template-list-component [data-controller~='sortable-lists--list']")
      expect(root["data-sortable-lists-sortable-lists--item-outlet"])
        .to eq("#work-package-types-export-template-list-component [data-controller~='sortable-lists--item']")
    end
  end

  it_behaves_like "a sortable-lists list",
                  list_type: "pdf_export_templates",
                  name: I18n.t("types.edit.export_configuration.pdf_export_templates.label")
  it_behaves_like "a Border Box sortable list", row_count: 3
  it_behaves_like "no legacy drag-and-drop wiring"

  it "wires every row as a sortable item of type template", :aggregate_failures do
    sortable_records.each do |template|
      expect(rendered_component)
        .to have_css(".Box-row[data-sortable-lists--item-id-value='#{template.id}']") do |row|
        expect(row["data-controller"]).to eq("sortable-lists--item")
        expect(row["data-sortable-lists--item-type-value"]).to eq("pdf_export_templates")
        expect(row["data-sortable-lists--item-label-value"]).to eq(template.label)
        expect(row).to have_css(".DragHandle[data-sortable-lists--item-target~='handle']", visible: :all)
      end
    end
  end

  it "renders the enable-all and disable-all header actions", :aggregate_failures do
    expect(rendered_component).to have_link(accessible_name: I18n.t("projects.settings.actions.label_enable_all"))
    expect(rendered_component).to have_link(accessible_name: I18n.t("projects.settings.actions.label_disable_all"))
  end

  it "renders a unique wrapper for each template row" do
    sortable_records.each do |template|
      expect(rendered_component)
        .to have_css("#work-package-types-export-template-row-component-#{template.id}", count: 1)
    end
  end

  it "links each template label to its settings page" do
    sortable_records.each do |template|
      expect(rendered_component).to have_link(
        template.label,
        href: edit_settings_type_pdf_export_template_path(type_id: type.id, id: template.id)
      )
    end
  end

  it "labels each template toggle button with its template" do
    sortable_records.each do |template|
      expect(rendered_component).to have_button(
        accessible_name: I18n.t(
          "types.edit.export_configuration.pdf_export_templates.actions.label_toggle_template",
          template: template.label
        ),
        aria: { pressed: template.enabled }
      )
    end
  end

  context "when readonly" do
    subject(:rendered_component) { render_inline(described_class.new(variant:, readonly: true)) }

    it "renders no drag-and-drop wiring", :aggregate_failures do
      expect(rendered_component).to have_no_css('[data-controller~="sortable-lists"]')
      expect(rendered_component).to have_no_css('[data-controller~="sortable-lists--list"]')
      expect(rendered_component).to have_no_css('[data-controller~="sortable-lists--item"]')
      expect(rendered_component).to have_no_css(".DragHandle")
    end

    it "renders no header actions", :aggregate_failures do
      expect(rendered_component).to have_no_link(accessible_name: I18n.t("projects.settings.actions.label_enable_all"))
      expect(rendered_component).to have_no_link(accessible_name: I18n.t("projects.settings.actions.label_disable_all"))
    end

    it "renders each template label as plain text instead of a link to its settings page" do
      sortable_records.each do |template|
        expect(rendered_component).to have_no_link(
          href: edit_settings_type_pdf_export_template_path(type_id: type.id, id: template.id)
        )
        expect(rendered_component).to have_text(template.label)
      end
    end
  end
end
