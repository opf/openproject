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

RSpec.describe WorkPackageTypes::TypeRoutes do
  shared_let(:project) { create(:project) }
  shared_let(:root) { create(:type, name: "Bug") }
  shared_let(:owned_variant) { create(:type, name: "Ours", parent: root, project:) }

  # Every path the tab components can ask for. Calling them all is what catches a
  # mistyped helper name, which would otherwise only surface when a tab is opened.
  let(:no_argument_paths) do
    %i[
      index details defaults form_configuration workflow project_attributes pdf_export
      wizard wizard_submit workflow_matrix workflow_matrix_status_dialog
      workflow_matrix_confirm_statuses workflow_copy form_configuration_reset_dialog
      form_configuration_groups add_form_configuration_group toggle_project_attribute
      enable_all_project_attributes disable_all_project_attributes
      enable_all_pdf_templates disable_all_pdf_templates update_artefact_export projects
      breadcrumb_root_items parent_details
    ]
  end

  let(:keyed_paths) do
    %i[
      form_configuration_group edit_form_configuration_group move_form_configuration_group
      drop_form_configuration_group cancel_edit_form_configuration_group
      update_query_form_configuration_group drop_form_configuration_row
      move_form_configuration_row toggle_pdf_template drop_pdf_template
    ]
  end

  let(:aspect_paths) do
    %i[
      configuration_link_dialog configuration_copy_dialog configuration_independence_dialog
    ]
  end

  shared_examples "a complete set of type paths" do
    it "answers every argument-free path" do
      no_argument_paths.each do |name|
        expect { routes.public_send(name) }.not_to raise_error, "#{name} could not build a path"
      end
    end

    it "answers every keyed path" do
      keyed_paths.each do |name|
        expect { routes.public_send(name, "some-key") }.not_to raise_error, "#{name} could not build a path"
      end
    end

    it "answers every aspect path" do
      aspect_paths.each do |name|
        expect { routes.public_send(name, "workflows") }.not_to raise_error, "#{name} could not build a path"
      end
    end
  end

  describe "in global administration" do
    let(:routes) { described_class.for(owned_variant) }

    it_behaves_like "a complete set of type paths"

    # Where you are decides, not what the type is: an administrator browsing /types
    # configures an owned variant through the admin routes.
    it "builds admin paths even for a project-owned variant" do
      expect(routes.details).to eq("/types/#{owned_variant.id}/details/edit")
    end
  end

  describe "inside a project's settings" do
    let(:routes) { described_class.for(owned_variant, project:) }

    it_behaves_like "a complete set of type paths"

    it "stays inside the project" do
      expect(routes.details).to start_with("/projects/#{project.identifier}/settings/work_packages/types/variants")
    end

    # There is nothing to activate elsewhere, so the tab has no destination.
    it "has no projects tab" do
      expect(routes.projects).to be_nil
    end
  end
end
