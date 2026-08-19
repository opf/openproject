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

RSpec.describe "Work package type configuration source",
               :skip_csrf,
               type: :rails_request,
               with_flag: { subtypes: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:source) { create(:type) }

  let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

  before { login_as admin }

  context "when the subtypes feature is disabled", with_flag: { subtypes: false } do
    it "renders the tab's own editor without the reuse mode toggle" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("PDF Export templates")
      expect(response.body).not_to include("These settings belong to this type")
    end

    it "blocks the update endpoint" do
      put type_configuration_link_path(type_id: type.id, aspect:),
          params: { mode: "linked", source_id: source.id }

      expect(response).to have_http_status(:not_found)
      expect(type).not_to be_linked(aspect)
    end
  end

  describe "rendering the tabs" do
    it "renders the PDF tab with the mode toggle" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Independent")
    end

    it "renders the subject tab with the mode toggle" do
      get edit_type_subject_configuration_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Independent")
    end

    it "shows the type's own editor when Independent" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("PDF Export templates")
    end

    it "includes the irreversibility warning for switching an Independent type to Linked" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("The current settings are discarded and work packages of this type may be affected.")
    end

    it "hides the editor and shows the source picker when Linked" do
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source:)

      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("Source type")
      expect(response.body).not_to include("PDF Export templates")
    end

    it "explains the copy-on-adopt when a Linked type may switch to Independent" do
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source:)

      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("then removes the link. You can edit them freely afterwards.")
    end
  end

  describe "PUT update" do
    it "links the aspect to the chosen source" do
      put type_configuration_link_path(type_id: type.id, aspect:),
          params: { mode: "linked", source_id: source.id }

      expect(response).to be_redirect
      expect(type.source_for(aspect)).to eq(source)
    end

    it "switches the aspect back to independent" do
      type.link!(aspect, source:)

      put type_configuration_link_path(type_id: type.id, aspect:),
          params: { mode: "independent" }

      expect(response).to be_redirect
      expect(type.reload).not_to be_linked(aspect)
    end

    it "adopts a source's config when switching to independent with a source" do
      configured = create(:type)
      configured.pdf_export_templates.disable_all
      configured.save!

      put type_configuration_link_path(type_id: type.id, aspect:),
          params: { mode: "independent", source_id: configured.id }

      expect(type.reload).not_to be_linked(aspect)
      expect(type.export_templates_disabled).to eq(configured.export_templates_disabled)
    end

    it "does not persist an invalid (self) source and flashes an alert" do
      put type_configuration_link_path(type_id: type.id, aspect:),
          params: { mode: "linked", source_id: type.id }

      expect(type).not_to be_linked(aspect)
      expect(flash[:alert]).to be_present
      expect(flash[:notice]).to be_blank
    end

    it "does not link when no source was picked" do
      put type_configuration_link_path(type_id: type.id, aspect:),
          params: { mode: "linked", source_id: "" }

      expect(type).not_to be_linked(aspect)
      expect(flash[:alert]).to be_present
      expect(flash[:notice]).to be_blank
    end

    it "requires admin" do
      login_as create(:user)

      put type_configuration_link_path(type_id: type.id, aspect:),
          params: { mode: "linked", source_id: source.id }

      expect(response).not_to be_successful
      expect(type).not_to be_linked(aspect)
    end
  end
end
