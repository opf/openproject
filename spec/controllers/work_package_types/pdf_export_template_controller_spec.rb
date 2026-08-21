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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
