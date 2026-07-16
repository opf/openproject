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
      patch type_aspect_configuration_link_path(type, aspect),
            params: { type_configuration_link: { source_id: source.id } }

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

  describe "read-only preview of a Linked aspect" do
    it "shows the inherited subject pattern and links to the source" do
      source.update!(patterns: { subject: { blueprint: "PR-{{id}}", enabled: true } })
      type.link!(Type::ConfigurationLink::PATTERNS, source:)

      get edit_type_subject_configuration_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Configuration reused from")
      expect(response.body).to include("PR-{{id}}")
      expect(response.body).to include(edit_type_subject_configuration_path(source))
    end
  end

  describe "PATCH update (link)" do
    it "links the aspect to the chosen source" do
      patch type_aspect_configuration_link_path(type, aspect),
            params: { type_configuration_link: { source_id: source.id } }

      expect(response).to be_redirect
      expect(type.source_for(aspect)).to eq(source)
    end

    it "re-renders the picker with an inline error instead of persisting a cyclic link" do
      # The source already borrows from the type, so linking back would close a loop.
      create(:type_configuration_link, type: source, source: type, aspect:)

      patch type_aspect_configuration_link_path(type, aspect),
            params: { type_configuration_link: { source_id: source.id } },
            as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("would link these configurations in a loop")
      expect(type.reload).not_to be_linked(aspect)
      expect(flash[:alert]).to be_blank
    end

    it "does not link when no source was picked" do
      patch type_aspect_configuration_link_path(type, aspect),
            params: { type_configuration_link: { source_id: "" } },
            as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(type).not_to be_linked(aspect)
      expect(flash[:alert]).to be_blank
    end

    it "requires admin" do
      login_as create(:user)

      patch type_aspect_configuration_link_path(type, aspect),
            params: { type_configuration_link: { source_id: source.id } }

      expect(response).not_to be_successful
      expect(type).not_to be_linked(aspect)
    end
  end

  describe "DELETE destroy (make independent)" do
    it "switches the aspect back to independent" do
      type.link!(aspect, source:)

      delete type_aspect_configuration_link_path(type, aspect)

      expect(response).to be_redirect
      expect(type.reload).not_to be_linked(aspect)
    end

    it "adopts a source's config while switching to independent" do
      configured = create(:type)
      configured.pdf_export_templates.disable_all
      configured.save!

      delete type_aspect_configuration_link_path(type, aspect),
             params: { type_configuration_link: { source_id: configured.id } }

      expect(type.reload).not_to be_linked(aspect)
      expect(type.export_templates_disabled).to eq(configured.export_templates_disabled)
    end
  end
end
