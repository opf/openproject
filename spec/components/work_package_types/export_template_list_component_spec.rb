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

require "rails_helper"

RSpec.describe WorkPackageTypes::ExportTemplateListComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:draggable_records) { variant.pdf_export_templates.list }

  subject(:rendered_component) { render_inline(described_class.new(variant:)) }

  def drop_url_for(template)
    drop_type_pdf_export_template_path(**variant.path_args, id: template.id)
  end

  it_behaves_like "rendering Box", row_count: 3
  it_behaves_like "a reorderable Border Box List", drag_type: "template"

  it "renders the enable-all and disable-all header actions", :aggregate_failures do
    expect(rendered_component).to have_link(accessible_name: I18n.t("projects.settings.actions.label_enable_all"))
    expect(rendered_component).to have_link(accessible_name: I18n.t("projects.settings.actions.label_disable_all"))
  end

  it "renders a unique wrapper for each template row" do
    draggable_records.each do |template|
      expect(rendered_component)
        .to have_css("#work-package-types-export-template-row-component-#{template.id}", count: 1)
    end
  end

  it "links each template label to its settings page" do
    draggable_records.each do |template|
      expect(rendered_component).to have_link(
        template.label,
        href: edit_settings_type_pdf_export_template_path(**variant.path_args, id: template.id)
      )
    end
  end

  it "labels each template toggle button with its template" do
    draggable_records.each do |template|
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
      expect(rendered_component).to have_no_css('[data-controller~="generic-drag-and-drop"]')
      expect(rendered_component).to have_no_css("[data-generic-drag-and-drop-target]")
      expect(rendered_component).to have_no_css("[data-draggable-id]")
      expect(rendered_component).to have_no_css(".op-draggable-list-item--drag-handle")
    end

    it "renders no header actions", :aggregate_failures do
      expect(rendered_component).to have_no_link(accessible_name: I18n.t("projects.settings.actions.label_enable_all"))
      expect(rendered_component).to have_no_link(accessible_name: I18n.t("projects.settings.actions.label_disable_all"))
    end

    it "renders each template label as plain text instead of a link to its settings page" do
      draggable_records.each do |template|
        expect(rendered_component).to have_no_link(
          href: edit_settings_type_pdf_export_template_path(**variant.path_args, id: template.id)
        )
        expect(rendered_component).to have_text(template.label)
      end
    end
  end
end
