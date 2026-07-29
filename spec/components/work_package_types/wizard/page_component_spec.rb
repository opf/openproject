# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "rails_helper"

RSpec.describe WorkPackageTypes::Wizard::PageComponent, type: :component, with_flag: { type_variants: true } do
  let(:parent) { create(:type, name: "Phase") }
  let(:type) { create(:type) }

  before { login_as(create(:admin)) }

  describe "step dispatch" do
    # The page's job is to render the right body per step; each body's own content is
    # its responsibility, so we stub it. Inline-form steps (details/defaults/workflows)
    # render through StepEditors and are covered by their editors' specs.
    {
      form_configuration: WorkPackageTypes::Wizard::FormConfigurationStepComponent,
      project_attributes: WorkPackageTypes::Wizard::ProjectAttributesStepComponent,
      projects: WorkPackageTypes::ProjectsComponent,
      pdf: WorkPackageTypes::Wizard::PdfStepComponent
    }.each do |step, component|
      it "renders #{component} on the #{step} step" do
        stubbed = instance_double(component, render_in: "STUB[#{step}]")
        allow(component).to receive(:new).and_return(stubbed)

        render_inline(described_class.new(type:, current_step: step))

        expect(component).to have_received(:new)
        expect(page).to have_text("STUB[#{step}]")
      end
    end
  end

  describe "sidebar step markers" do
    it "marks the current and pending steps, and completed steps by reuse mode" do
      type.link!(Type::ConfigurationLink::DEFAULTS, source: parent)

      render_inline(described_class.new(type:, current_step: :workflows))

      expect(find_test_selector("wizard-step-details")).to have_css(".octicon-pencil")
      expect(find_test_selector("wizard-step-defaults")).to have_css(".octicon-link")
      expect(find_test_selector("wizard-step-workflows")).to have_css(".octicon-dot-fill")
      expect(find_test_selector("wizard-step-pdf")).to have_css(".octicon-circle")
    end
  end

  describe "cancel and close targets" do
    let(:url_helpers) { Rails.application.routes.url_helpers }

    context "when the type has not been created yet" do
      it "points the close (X) and cancel actions to the type list" do
        render_inline(described_class.new(type: build(:type), current_step: :details))

        expect(page).to have_css("a.PageHeader-action[href='#{url_helpers.types_path}']")
        expect(page).to have_css(".op-step-wizard-footer--actions-right a[href='#{url_helpers.types_path}']")
      end
    end

    context "when the type has been created" do
      it "points the close (X) and cancel actions to the type's edit page" do
        edit_href = url_helpers.edit_type_details_path(type_id: type.id)

        render_inline(described_class.new(type:, current_step: :defaults))

        expect(page).to have_css("a.PageHeader-action[href='#{edit_href}']")
        expect(page).to have_css(".op-step-wizard-footer--actions-right a[href='#{edit_href}']")
      end
    end
  end

  describe "breadcrumbs" do
    it "links the parent the variant is being created under" do
      render_inline(described_class.new(type: build(:type, parent:), current_step: :details))

      expect(page).to have_link("Phase",
                                href: Rails.application.routes.url_helpers.edit_type_details_path(type_id: parent.id))
    end

    it "omits the parent crumb when there is none" do
      render_inline(described_class.new(type: build(:type), current_step: :details))

      expect(page).to have_no_link("Phase")
    end
  end
end
