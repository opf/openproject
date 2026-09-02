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

RSpec.describe WorkPackageTypes::ProjectAttributes::IndexComponent, type: :component do
  include Rails.application.routes.url_helpers

  current_user { create(:admin) }

  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:sections) { ProjectCustomFieldSection.grouped_in_order(ProjectCustomField.visible) }

  subject(:rendered_component) do
    render_inline(described_class.new(variant:, project_custom_field_sections: sections))
  end

  def blankslate_text(mode, key)
    I18n.t("types.edit.project_attributes.blankslate.#{mode}.#{key}")
  end

  context "when the variant configures the aspect itself" do
    context "with no project attributes at all" do
      it "renders the blankslate instead of the filter", :aggregate_failures do
        expect(rendered_component).to have_test_selector("type-project-attributes-blankslate",
                                                         text: blankslate_text(:manual, :title))
        expect(rendered_component).to have_link("create project attributes",
                                                href: admin_settings_project_custom_fields_path)
        expect(rendered_component).to have_no_field("border-box-filter")
      end
    end

    context "with project attributes" do
      before { create(:project_custom_field) }

      it "renders the sections and the filter", :aggregate_failures do
        expect(rendered_component).to have_no_test_selector("type-project-attributes-blankslate")
        expect(rendered_component).to have_css(".Box-row")
        expect(rendered_component).to have_field("border-box-filter")
      end
    end
  end

  context "when the variant is linked for the aspect", with_flag: { type_variants: true } do
    let(:source_type) { create(:type) }
    let(:source) { source_type.default_variant }
    let(:custom_field) { create(:project_custom_field) }

    before do
      custom_field
      link_configuration(variant, source:, aspect: TypeVariant::PROJECT_ATTRIBUTES)
    end

    context "when the source enables no project attribute" do
      it "renders the blankslate instead of the filter", :aggregate_failures do
        expect(rendered_component).to have_test_selector("type-project-attributes-blankslate",
                                                         text: blankslate_text(:inherited, :title))
        expect(rendered_component).to have_text(blankslate_text(:inherited, :description))
        expect(rendered_component).to have_no_field("border-box-filter")
      end
    end

    context "when the source enables a project attribute" do
      before do
        ProjectCustomFieldTypeMapping.create!(type_variant: source, project_custom_field: custom_field)
      end

      it "renders the sections and the filter", :aggregate_failures do
        expect(rendered_component).to have_no_test_selector("type-project-attributes-blankslate")
        expect(rendered_component).to have_css(".Box-row")
        expect(rendered_component).to have_field("border-box-filter")
      end
    end
  end
end
