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

RSpec.describe WorkPackageTypes::FormConfigurationComponent, type: :component do
  include_context "with variant scope"

  let(:type) { create(:type, name: "Bug") }
  let(:base) { type.default_variant }
  let(:variant) { create(:type_variant, type:, variant_name: "Mobile app bug") }
  let(:no_filter_query) { "{}" }
  let(:context) { WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil) }
  let(:form_attributes) { ApplicationController.helpers.form_configuration_groups(context) }

  before do
    base.attribute_groups = [["Reused From Source", %w[assignee]]]
    base.save!
    login_as(create(:admin))
  end

  def render_component
    render_inline(described_class.new(context:, form_attributes:, no_filter_query:))
  end

  context "when the form configuration aspect is linked" do
    before do
      link_configuration(variant, aspect: TypeVariant::FORM_CONFIGURATION)
    end

    it "renders the base's groups read-only", :aggregate_failures do
      render_component

      expect(page).to have_text("Reused From Source")
      expect(page).to have_no_css(".type-form-configuration-page--sidebar")
      expect(page).to have_no_test_selector("type-form-configuration-reset-button")
      expect(page).to have_no_test_selector("type-form-configuration-add-button")
      expect(page).to have_no_css("[data-draggable-type='group']")
    end

    # An exclusion the variant owns is reversible from here, so its row stays and the switch
    # shows it off.
    describe "exclusions" do
      before do
        base.attribute_groups = [["People", %w[assignee responsible]]]
        base.save!
      end

      it "lists a row the variant excludes itself, switched off", :aggregate_failures do
        exclude_configuration_elements(variant, aspect: TypeVariant::FORM_CONFIGURATION, elements: %w[assignee])

        render_component

        expect(page).to have_text("People")
        toggle = page.find("[data-test-selector='toggle-form-config-exclusion-assignee'] > button")
        expect(toggle["aria-pressed"]).to eq("false")
      end

      it "renders a query section nothing excludes" do
        base.attribute_groups = [["People", %w[assignee]], ["Related", [create(:query)]]]
        base.save!

        render_component

        expect(page).to have_text("Related")
      end
    end
  end

  context "when independent" do
    it "renders read-only all the same, since the form is edited on its own page", :aggregate_failures do
      render_component

      expect(page).to have_no_css(".type-form-configuration-page--sidebar")
      expect(page).to have_no_test_selector("type-form-configuration-add-button")
    end
  end

  context "on the form's own page" do
    let(:context) { WorkPackageTypes::FormConfiguration::EditorContext.new(form_configuration: variant.form_configuration) }

    it "renders the editable page with the inactive sidebar", :aggregate_failures do
      render_component

      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end
  end
end
