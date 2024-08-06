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

RSpec.describe "bim/ifc_models/ifc_models/index" do
  let(:project) { create(:project, enabled_module_names: %i[bim]) }
  let(:ifc_model) do
    create(:ifc_model,
           uploader: uploader_user,
           title: "office.ifc",
           project:).tap do |model|
      model.uploader = uploader_user
    end
  end
  let(:role) do
    create(:project_role,
           permissions: %i[view_ifc_models manage_ifc_models])
  end
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:uploader_user) { user }

  before do
    assign(:project, project)
    ifc_models = [ifc_model]

    without_partial_double_verification do
      allow(ifc_models).to receive(:defaults).and_return(ifc_models)
    end

    assign(:ifc_models, ifc_models)

    controller.request.path_parameters[:project_id] = project.id

    allow(User).to receive(:current).and_return(user)
  end

  context "with permission manage_ifc_models" do
    context "with ifc_attachment" do
      it "lists the IFC model with all three buttons" do
        render
        expect(rendered).to have_text("office.ifc")
        expect(rendered).to have_link("Download")
        expect(rendered).to have_link("Delete")
        expect(rendered).to have_link("Edit")
        expect(rendered).to have_text("Pending")
      end
    end

    %w[processing completed error].each do |state|
      context "with conversion_status '#{state}'" do
        before do
          ifc_model.conversion_status = Bim::IfcModels::IfcModel.conversion_statuses[state.to_sym]
          ifc_model.conversion_error_message = "Conversion went wrong" if state == "error"
          render
        end

        it 'renders the conversion status to be "Processing"' do
          expect(rendered).to have_text(state.capitalize)
          expect(rendered).to have_text("Conversion went wrong") if state == "error"
        end
      end
    end

    context "without ifc_attachment" do
      let(:ifc_model) do
        create(:ifc_model_without_ifc_attachment,
               title: "office.ifc",
               project:)
      end

      it "lists the IFC model with all but the download button" do
        render
        expect(rendered).to have_text("office.ifc")
        expect(rendered).to have_no_link("Download")
        expect(rendered).to have_link("Delete")
        expect(rendered).to have_link("Edit")
      end
    end
  end

  context "without permission manage_ifc_models" do
    it "only shows the download button" do
      render
      expect(rendered).to have_link("Download")
    end
  end
end
