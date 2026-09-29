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
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Mobile") }

  let(:aspect) { TypeVariant::PDF_EXPORT }

  before { login_as admin }

  describe "rendering the tabs" do
    it "renders a variant's PDF tab with the mode selector in manual mode" do
      get edit_type_pdf_export_template_index_path(**variant.path_args)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Configure this page manually")
    end

    it "renders a variant's subject tab with the mode selector in manual mode" do
      get edit_type_defaults_path(**variant.path_args)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Configure this page manually")
    end

    it "omits the mode selector on a type's own tab, since a type has no mode" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Configure this page manually")
    end

    it "shows the type's own editor when Independent" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("PDF Export templates")
    end

    it "links to the parent type in the inherit option when Linked" do
      link_configuration(variant, aspect: TypeVariant::PDF_EXPORT)

      get edit_type_pdf_export_template_index_path(type_id: type.id, variant_id: variant.id)

      expect(response.body).to include(type.default_variant.composite_name)
      expect(response.body).to include(
        edit_type_pdf_export_template_index_path(type_id: type.id, variant_id: type.default_variant.id)
      )
    end

    it "shows a read-only preview instead of the editable editor when Linked" do
      link_configuration(variant, aspect: TypeVariant::PDF_EXPORT)

      get edit_type_pdf_export_template_index_path(type_id: type.id, variant_id: variant.id)

      # the preview lists the templates but drops the editable enable/disable actions
      expect(response.body).to include("PDF Export templates")
      expect(response.body).not_to include("enable-all-pdf-export-templates")
    end
  end

  describe "read-only preview of a Linked aspect" do
    it "shows the inherited subject pattern and links to the parent" do
      type.default_variant.update!(patterns: { subject: { blueprint: "PR-{{id}}", enabled: true } })
      link_configuration(variant, aspect: TypeVariant::DEFAULTS)

      get edit_type_defaults_path(type_id: type.id, variant_id: variant.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("PR-{{id}}")
      expect(response.body).to include(
        edit_type_defaults_path(type_id: type.id, variant_id: type.default_variant.id)
      )
    end
  end

  describe "GET dialog" do
    it "renders the switch-to-inherited confirmation dialog" do
      get type_configuration_link_dialog_path(type_id: type.id, variant_id: variant.id, aspect:),
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Switch configuration mode")
      expect(response.body).to include("I understand that this will override the current settings")
    end

    it "submits back to the switch action of the variant it was opened for" do
      get type_configuration_link_dialog_path(type_id: type.id, variant_id: variant.id, aspect:),
          as: :turbo_stream

      expect(response.body).to include(
        type_configuration_link_switch_path(type_id: type.id, variant_id: variant.id, aspect:)
      )
    end

    it "is not found for an unknown aspect" do
      get type_configuration_link_dialog_path(type_id: type.id, variant_id: variant.id, aspect: "not_an_aspect"),
          as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST switch" do
    it "links the aspect to the parent, closes the dialog and dispatches the reload event" do
      post type_configuration_link_switch_path(type_id: type.id, variant_id: variant.id, aspect:),
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(variant.reload.source_for(aspect)).to eq(type.default_variant)
      expect(response.body).to include("closeDialog")
      expect(response.body).to include("dispatchEvent")
      expect(response.body)
        .to include(WorkPackageTypes::ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME)
      expect(response.body).to include(I18n.t("types.edit.reuse_mode.inherited.success"))
    end

    it "flashes an error and links nothing on a base variant, which cannot inherit" do
      expect(type.default_variant).not_to be_linked(aspect)

      post type_configuration_link_switch_path(type_id: type.id, aspect:), as: :turbo_stream

      expect(response.body).not_to include("dispatchEvent")
      expect(type.default_variant.reload).not_to be_linked(aspect)
    end

    it "requires admin" do
      login_as create(:user)

      post type_configuration_link_switch_path(type_id: type.id, variant_id: variant.id, aspect:),
           as: :turbo_stream

      expect(response).not_to be_successful
      expect(variant.reload).not_to be_linked(aspect)
    end
  end
end
