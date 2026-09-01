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
  include Rails.application.routes.url_helpers

  let(:source) { create(:type, name: "Phase") }
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
      link_configuration(type, source:, aspect: TypeVariant::DEFAULTS)

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

  # The wizard carries its own header, so fixing the tabs' breadcrumb left this one still leading
  # a project administrator up through administration.
  describe "the trail it leads back through" do
    shared_let(:project) { create(:project, name: "Apollo") }
    shared_let(:trail_type) { create(:type, name: "Bug") }

    context "when the wizard is reached from administration" do
      before { render_inline(described_class.new(type: trail_type, current_step: :details)) }

      it "leads back through administration" do
        expect(page).to have_link("Administration", href: admin_index_path)
      end

      it "does not name a project" do
        expect(page).to have_no_link("Apollo")
      end
    end

    context "when the wizard is reached from a project's settings" do
      before do
        vc_test_controller.instance_variable_set(:@project, project)
        render_inline(described_class.new(type: trail_type, current_step: :details))
      end

      it "leads back through the project" do
        expect(page).to have_link("Apollo", href: project_overview_path(project.id))
        expect(page).to have_link("Project settings", href: project_settings_general_path(project.id))
      end

      it "offers no way up into administration" do
        expect(page).to have_no_link("Administration")
      end

      # types_path would resolve to an administration URL carrying the project as a query
      # parameter, which is a dead link for the caller.
      it "cancels back to the project's own list of types" do
        expect(page).to have_css("a[href='#{project_settings_work_packages_types_path(project)}']")
      end
    end
  end
end
