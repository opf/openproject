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

RSpec.describe WorkPackageTypes::ProjectAttributes::IndexComponent, type: :component do
  include Rails.application.routes.url_helpers

  include_context "with variant scope"

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

  context "when the variant is linked for the aspect" do
    let(:variant) { create(:type_variant, type:) }
    let(:custom_field) { create(:project_custom_field) }

    before do
      custom_field
      link_configuration(variant, aspect: TypeVariant::PROJECT_ATTRIBUTES)
    end

    context "when the base enables no project attribute" do
      it "renders the blankslate instead of the filter", :aggregate_failures do
        expect(rendered_component).to have_test_selector("type-project-attributes-blankslate",
                                                         text: blankslate_text(:inherited, :title))
        expect(rendered_component).to have_text(blankslate_text(:inherited, :description))
        expect(rendered_component).to have_no_field("border-box-filter")
      end
    end

    context "when the base enables a project attribute" do
      before do
        ProjectCustomFieldTypeMapping.create!(type_variant: type.default_variant, project_custom_field: custom_field)
      end

      it "renders the sections and the filter", :aggregate_failures do
        expect(rendered_component).to have_no_test_selector("type-project-attributes-blankslate")
        expect(rendered_component).to have_css(".Box-row")
        expect(rendered_component).to have_field("border-box-filter")
      end
    end
  end
end
