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
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:source) { create(:type) }

  let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

  before { login_as admin }

  context "when the variants feature is disabled", with_flag: { type_variants: false } do
    it "renders the tab's own editor without the reuse mode banner" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("PDF Export templates")
      expect(response.body).not_to include("Independent mode")
      expect(response.body).not_to include("Linked mode")
    end

    it "blocks the switch endpoint" do
      post type_configuration_link_switch_path(type_id: type.id, aspect:),
           params: { source_id: source.id }

      expect(response).to have_http_status(:not_found)
      expect(type).not_to be_linked(aspect)
    end
  end

  describe "rendering the tabs" do
    it "renders the PDF tab with the reuse mode banner in independent mode" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Independent mode")
    end

    it "renders the subject tab with the reuse mode banner in independent mode" do
      get edit_type_defaults_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Independent mode")
    end

    it "shows the type's own editor when Independent" do
      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("PDF Export templates")
    end

    it "shows the linked banner and links to the source type when Linked" do
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source:)

      get edit_type_pdf_export_template_index_path(type_id: type.id)

      expect(response.body).to include("Linked mode")
      expect(response.body).to include(source.name)
    end

    it "shows a read-only preview instead of the editable editor when Linked" do
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source:)

      get edit_type_pdf_export_template_index_path(type_id: type.id)

      # the preview lists the templates but drops the editable enable/disable actions
      expect(response.body).to include("PDF Export templates")
      expect(response.body).not_to include("enable-all-pdf-export-templates")
    end
  end

  describe "read-only preview of a Linked aspect" do
    it "shows the inherited subject pattern and links to the source" do
      source.update!(patterns: { subject: { blueprint: "PR-{{id}}", enabled: true } })
      type.link!(Type::ConfigurationLink::DEFAULTS, source:)

      get edit_type_defaults_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Linked mode")
      expect(response.body).to include("PR-{{id}}")
      expect(response.body).to include(edit_type_details_path(type_id: source.id))
    end
  end

  describe "GET dialog" do
    it "renders the linked source picker" do
      get type_configuration_link_dialog_path(type_id: type.id, aspect:), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Linked mode")
      expect(response.body).to include("Switch")
    end

    it "lists every source by composite name, families kept together, the parent flagged" do
      parent = create(:type, name: "Feature")
      create(:type, name: "Small", parent:)
      create(:type, name: "Big", parent:)
      variant = create(:type, name: "Mobile", parent:)

      get type_configuration_link_dialog_path(type_id: variant.id, aspect:), as: :turbo_stream

      expect(source_option_labels).to eq(
        [type.name, source.name, "Feature (parent)", "Feature: Big", "Feature: Small"]
      )
    end

    it "is not found for an unknown aspect" do
      get type_configuration_link_dialog_path(type_id: type.id, aspect: "not_an_aspect"), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "is not found when the variants feature is disabled", with_flag: { type_variants: false } do
      get type_configuration_link_dialog_path(type_id: type.id, aspect:), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST confirm" do
    it "renders the switch-configuration confirmation when currently Independent" do
      post type_configuration_link_confirm_path(type_id: type.id, aspect:),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("closeDialog")
      expect(response.body).to include("Switch configuration mode?")
      expect(response.body).to include("I understand that this will override the current settings")
    end

    it "renders the change-source confirmation when currently Linked" do
      type.link!(aspect, source: create(:type))
      other = create(:type, name: "Feature")

      post type_configuration_link_confirm_path(type_id: type.id, aspect:),
           params: { source_id: other.id },
           as: :turbo_stream

      expect(response.body).to include("Change source type?")
      expect(response.body).to include("Feature")
    end

    it "flashes an error when no source was picked" do
      post type_configuration_link_confirm_path(type_id: type.id, aspect:),
           params: { source_id: "" },
           as: :turbo_stream

      expect(response.body).not_to include("Switch configuration mode?")
      expect(response.body).to include(I18n.t("types.edit.reuse_mode.linked.invalid_source"))
    end
  end

  describe "POST switch" do
    it "links the aspect, closes the dialog and dispatches the reload event" do
      post type_configuration_link_switch_path(type_id: type.id, aspect:),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(type.reload.source_for(aspect)).to eq(source)
      expect(response.body).to include("closeDialog")
      expect(response.body).to include("dispatchEvent")
      expect(response.body)
        .to include(WorkPackageTypes::ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME)
      expect(response.body).to include(I18n.t("types.edit.reuse_mode.linked.success"))
    end

    it "flashes an error and links nothing on a cyclic source" do
      create(:type_configuration_link, type: source, source: type, aspect:)

      post type_configuration_link_switch_path(type_id: type.id, aspect:),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response.body).not_to include("dispatchEvent")
      expect(type.reload).not_to be_linked(aspect)
    end

    it "requires admin" do
      login_as create(:user)

      post type_configuration_link_switch_path(type_id: type.id, aspect:),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response).not_to be_successful
      expect(type.reload).not_to be_linked(aspect)
    end
  end

  describe "with project-owned variants" do
    shared_let(:owner) { create(:project) }
    shared_let(:stranger) { create(:project) }
    shared_let(:root) { create(:type, name: "Bug") }
    shared_let(:owned_variant) { create(:type, name: "Ours", parent: root, project: owner) }
    shared_let(:sibling) { create(:type, name: "Sibling", parent: root, project: owner) }
    shared_let(:foreign_variant) { create(:type, name: "Theirs", parent: root, project: stranger) }

    it "keeps another project's variant out of the picker" do
      get type_configuration_link_dialog_path(type_id: owned_variant.id, aspect:), as: :turbo_stream

      expect(source_option_labels).not_to include("Bug: Theirs")
    end

    it "offers a variant owned by the same project" do
      get type_configuration_link_dialog_path(type_id: owned_variant.id, aspect:), as: :turbo_stream

      expect(source_option_labels).to include("Bug: Sibling")
    end

    # A variant links every aspect to its parent on creation, so isolation shows up as the
    # source staying put rather than as the type being unlinked.
    it "refuses another project's variant as a source" do
      post type_configuration_link_switch_path(type_id: owned_variant.id, aspect:),
           params: { source_id: foreign_variant.id },
           as: :turbo_stream

      expect(owned_variant.reload.source_for(aspect)).to eq(root)
    end

    it "accepts a variant owned by the same project" do
      post type_configuration_link_switch_path(type_id: owned_variant.id, aspect:),
           params: { source_id: sibling.id },
           as: :turbo_stream

      expect(owned_variant.reload.source_for(aspect)).to eq(sibling)
    end
  end

  # A decorated autocompleter ships its options to the Angular component as a
  # JSON payload rather than rendering them as markup.
  def source_option_labels
    autocompleter = Nokogiri::HTML5.fragment(response.body).at_css("opce-autocompleter")

    JSON.parse(autocompleter["data-items"]).pluck("name")
  end
end
