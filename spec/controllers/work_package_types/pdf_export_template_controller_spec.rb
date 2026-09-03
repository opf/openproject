# frozen_string_literal: true

# -- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++
#

require "spec_helper"

RSpec.describe WorkPackageTypes::PdfExportTemplateController do
  let(:user) { create(:admin) }
  let(:wp_type) { create(:type) }
  let(:variant) { wp_type.default_variant }

  current_user { user }

  context "when the user is not logged in" do
    let(:user) { User.anonymous }

    it "responds with forbidden" do
      put :enable_all, params: { type_id: wp_type.id }, as: :turbo_stream
      expect(response).to have_http_status :unauthorized
    end
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    it "responds with forbidden" do
      put :enable_all, params: { type_id: wp_type.id }, as: :turbo_stream
      expect(response).to have_http_status :forbidden
    end
  end

  context "when an admin" do
    def put_reload(endpoint, params = {})
      put endpoint, params: { type_id: wp_type.id }.merge(params), as: :turbo_stream
      variant.reload
    end

    def post_reload(endpoint, params = {})
      post endpoint, params: { type_id: wp_type.id }.merge(params), as: :turbo_stream
      variant.reload
    end

    context "with no enabled templates" do
      before do
        variant.pdf_export_templates.disable_all
        variant.save!
      end

      it "enables all templates" do
        put_reload :enable_all
        expect(variant.export_templates_disabled.length).to eq(0)
      end

      it "reorder a template" do
        first = variant.pdf_export_templates.list.first
        put_reload :drop, { id: first.id, position: 2 } # drop index starts at 1
        variant.pdf_export_templates.list[1].id == first.id
      end

      it "toggles enabled/disabled for a template" do
        first = variant.pdf_export_templates.list.first
        post_reload :toggle, { id: first.id }
        expect(variant.pdf_export_templates.find(first.id).enabled).to be(true)
      end
    end

    context "with all enabled templates" do
      before do
        variant.pdf_export_templates.enable_all
        variant.save!
      end

      it "disables all templates" do
        put_reload :disable_all
        expect(variant.export_templates_disabled.length).to eq(variant.pdf_export_templates.list.length)
      end
    end

    context "when linked to a source type", with_flag: { type_variants: true } do
      render_views

      before { link_configuration(wp_type, source: create(:type), aspect: TypeVariant::PDF_EXPORT) }

      it "refuses enable_all with a forbidden turbo-stream flash" do
        expect { put_reload :enable_all }.not_to raise_error
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include(I18n.t("types.edit.export_configuration.templates.readonly_error"))
      end

      it "refuses disable_all with a forbidden turbo-stream flash" do
        expect { put_reload :disable_all }.not_to raise_error
        expect(response).to have_http_status(:forbidden)
      end

      it "refuses toggle with a forbidden turbo-stream flash" do
        first = variant.pdf_export_templates.list.first
        expect { post_reload :toggle, { id: first.id } }.not_to raise_error
        expect(response).to have_http_status(:forbidden)
      end

      it "refuses drop with a forbidden turbo-stream flash" do
        first = variant.pdf_export_templates.list.first
        expect { put_reload :drop, { id: first.id, position: 2 } }.not_to raise_error
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "#edit" do
      render_views

      it "renders the export configuration page including the artefact export form" do
        get :edit, params: { type_id: wp_type.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("types.edit.export_configuration.artefact_export.section_title"))
      end

      context "when no automatically-managed Nextcloud storage is configured" do
        it "marks the file link option as unavailable" do
          get :edit, params: { type_id: wp_type.id }

          expect(response.body).to include(I18n.t("types.edit.export_configuration.artefact_export.unavailable"))
        end
      end

      context "when an automatically-managed Nextcloud storage is configured" do
        before { create(:nextcloud_storage, :as_automatically_managed) }

        it "offers the file link option without the unavailable hint" do
          get :edit, params: { type_id: wp_type.id }

          expect(response.body).not_to include(I18n.t("types.edit.export_configuration.artefact_export.unavailable"))
        end
      end
    end

    describe "#edit_settings" do
      render_views

      it "renders the settings page for a known template" do
        template = variant.pdf_export_templates.find("attributes")

        get :edit_settings, params: { type_id: wp_type.id, id: template.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          I18n.t("types.edit.export_configuration.templates.settings.title", template: template.label)
        )
      end

      it "404s for an unknown template id" do
        get :edit_settings, params: { type_id: wp_type.id, id: "bogus" }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "#update_settings" do
      let(:template) { variant.pdf_export_templates.find("attributes") }

      it "stores the submitted settings and redirects to the tab overview" do
        patch :update_settings,
              params: { type_id: wp_type.id, id: template.id, footer_text: "Custom footer",
                        page_orientation: "landscape" }

        expect(response).to redirect_to(edit_type_pdf_export_template_index_path(type_id: wp_type.id))
        expect(variant.reload.pdf_export_templates.settings_for("attributes"))
          .to eq(footer_text: "Custom footer", page_orientation: "landscape")
      end

      it "does not store blank fields, so their runtime defaults keep applying" do
        patch :update_settings,
              params: { type_id: wp_type.id, id: template.id, footer_text: "",
                        page_orientation: "portrait", hyphenation: "false", hyphenation_language: "" }

        expect(variant.reload.pdf_export_templates.settings_for("attributes"))
          .to eq(page_orientation: "portrait", hyphenation: "false")
      end

      it "clears a previously stored value when its field is submitted blank" do
        variant.pdf_export_templates.update_settings("attributes", "footer_text" => "Custom footer")
        variant.save!

        patch :update_settings,
              params: { type_id: wp_type.id, id: template.id, footer_text: "", page_orientation: "landscape" }

        expect(variant.reload.pdf_export_templates.settings_for("attributes"))
          .to eq(page_orientation: "landscape")
      end

      it "resets the stored settings to defaults when submitted as a reset" do
        variant.pdf_export_templates.update_settings("attributes", "footer_text" => "Custom footer")
        variant.save!

        patch :update_settings, params: { type_id: wp_type.id, id: template.id, commit: "reset" }

        expect(variant.reload.pdf_export_templates.settings_for("attributes")).to eq({})
      end

      it "404s for an unknown template id" do
        patch :update_settings, params: { type_id: wp_type.id, id: "bogus" }

        expect(response).to have_http_status(:not_found)
      end

      it "stores the artefact template's lifecycle/budget defaults and resets them" do
        artefact_template = variant.pdf_export_templates.find("artefact")

        patch :update_settings,
              params: { type_id: wp_type.id, id: artefact_template.id,
                        include_lifecycle: "true", include_budget: "true" }

        expect(variant.reload.pdf_export_templates.settings_for("artefact"))
          .to eq(include_lifecycle: "true", include_budget: "true")

        patch :update_settings, params: { type_id: wp_type.id, id: artefact_template.id, commit: "reset" }

        expect(variant.reload.pdf_export_templates.settings_for("artefact")).to eq({})
      end

      context "when the type links its PDF export config to a source type" do
        let(:source) { create(:type).default_variant }

        before do
          source.pdf_export_templates.update_settings("attributes", "footer_text" => "Source footer")
          source.save!
          link_configuration(wp_type, source:, aspect: TypeVariant::PDF_EXPORT)
        end

        it "does not change the effective (inherited) settings", with_flag: { type_variants: true } do
          patch :update_settings,
                params: { type_id: wp_type.id, id: template.id, footer_text: "Attempted override" }

          expect(variant.reload.pdf_export_templates.settings_for("attributes")[:footer_text]).to eq("Source footer")
        end

        it "redirects with an alert instead of raising", with_flag: { type_variants: true } do
          patch :update_settings,
                params: { type_id: wp_type.id, id: template.id, footer_text: "Attempted override" }

          expect(response).to redirect_to(edit_type_pdf_export_template_index_path(type_id: wp_type.id))
          expect(flash[:alert]).to eq(I18n.t("types.edit.export_configuration.templates.readonly_error"))
        end
      end
    end

    describe "#update_artefact_export" do
      let(:param_key) { variant.model_name.param_key.to_sym }

      it "stores a valid artefact export mode and responds with a turbo stream" do
        put :update_artefact_export,
            params: { type_id: wp_type.id, param_key => { artefact_export_mode: Type::ArtefactExport::FILE_LINK } },
            as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(variant.reload.artefact_export_mode).to eq(Type::ArtefactExport::FILE_LINK)
      end

      it "rejects an invalid mode" do
        put :update_artefact_export,
            params: { type_id: wp_type.id, param_key => { artefact_export_mode: "bogus" } },
            as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(variant.reload.artefact_export_mode).to eq(Type::ArtefactExport::OFF)
      end

      it "rejects a request that nests the mode under an unrelated params key" do
        put :update_artefact_export,
            params: { type_id: wp_type.id, type: { artefact_export_mode: Type::ArtefactExport::FILE_LINK } },
            as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(variant.reload.artefact_export_mode).to eq(Type::ArtefactExport::OFF)
      end
    end
  end
end
