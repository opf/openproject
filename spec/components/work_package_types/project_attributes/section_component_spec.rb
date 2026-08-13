# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe WorkPackageTypes::ProjectAttributes::SectionComponent, type: :component do
  include Rails.application.routes.url_helpers

  current_user { create(:admin) }

  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:project_custom_field_section) { create(:project_custom_field_section, name: "Section title") }

  subject(:rendered_component) do
    render_inline(
      described_class.new(
        variant:,
        project_custom_field_section:,
        project_custom_fields:
      )
    )
  end

  context "with no custom fields in the section" do
    let(:project_custom_fields) { [] }

    it "renders the header and no rows", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-header", text: "Section title")
      expect(rendered_component).to have_no_css(".Box-row")
      expect(rendered_component).to have_no_css("[data-empty-list-item]")
      expect(rendered_component).to have_no_css(".blankslate")
    end
  end

  context "with custom fields in the section" do
    let(:project_custom_field) { create(:project_custom_field, project_custom_field_section:) }
    let(:project_custom_fields) { [project_custom_field] }

    it "renders a row for each custom field" do
      expect(rendered_component).to have_css(".Box-row", count: 1)
    end
  end
end
