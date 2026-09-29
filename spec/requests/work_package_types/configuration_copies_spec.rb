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

RSpec.describe "Work package type configuration copies",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:source_type) { create(:type, name: "Feature") }
  let(:source) { source_type.default_variant }
  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  before { login_as(admin) }

  describe "GET dialog" do
    it "renders the copy source dialog" do
      get type_configuration_copy_dialog_path(type_id: type.id, variant_id: variant.id, aspect:), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Copy configuration")
      expect(response.body).to include("Save and copy")
    end

    it "annotates the parent and orders variants under their root with the composite name" do
      named_variant = create(:type_variant, type: source_type, variant_name: "Web")
      root = create(:type, name: "Bug")
      create(:type_variant, type: root, variant_name: "Mobile")
      create(:type_variant, type: root, variant_name: "Desktop")

      get type_configuration_copy_dialog_path(type_id: source_type.id, variant_id: named_variant.id, aspect:),
          as: :turbo_stream

      expect(response.body).to include("Feature (parent)")
      expect(response.body).to include("Bug: Mobile")
      expect(response.body.index("Bug")).to be < response.body.index("Bug: Mobile")
      expect(response.body.index("Bug: Desktop")).to be < response.body.index("Bug: Mobile")
    end

    it "is not found for aspects without a copy service" do
      get type_configuration_copy_dialog_path(type_id: type.id, variant_id: variant.id, aspect: "unknown_aspect"),
          as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "is not found when the variants feature is disabled", with_flag: { type_variants: false } do
      get type_configuration_copy_dialog_path(type_id: type.id, variant_id: variant.id, aspect:), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST confirm" do
    it "closes the picker and renders the danger confirmation" do
      post type_configuration_copy_confirm_path(type_id: type.id, variant_id: variant.id, aspect:),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("closeDialog")
      expect(response.body).to include("Copy configuration?")
      expect(response.body).to include("I understand that this will override the current settings")
      expect(response.body).to include("Feature")
    end

    it "flashes an error when no source was picked" do
      post type_configuration_copy_confirm_path(type_id: type.id, variant_id: variant.id, aspect:),
           params: { source_id: "" },
           as: :turbo_stream

      expect(response.body).not_to include("Copy configuration?")
      expect(response.body).to include(I18n.t("types.edit.reuse_mode.copy.invalid_source"))
    end
  end

  describe "POST copy" do
    before do
      source.attribute_groups = [["copied group", %w[assignee]]]
      source.save!
    end

    it "copies the configuration, closes the dialog and dispatches the reload event" do
      post type_configuration_copy_copy_path(type_id: type.id, variant_id: variant.id, aspect:),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(variant.reload.attribute_groups.map(&:key)).to eq(["copied group"])

      expect(response.body).to include("closeDialog")
      expect(response.body).to include("dispatchEvent")
      expect(response.body)
        .to include(WorkPackageTypes::ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME)
      expect(response.body).to include(I18n.t("types.edit.reuse_mode.copy.success"))
    end

    it "flashes an error and copies nothing without a valid source" do
      post type_configuration_copy_copy_path(type_id: type.id, variant_id: variant.id, aspect:),
           params: { source_id: "" },
           as: :turbo_stream

      expect(response.body).not_to include("dispatchEvent")
      expect(variant.reload.read_attribute(:attribute_groups)).to be_empty
    end

    it "is not found for aspects without a copy service" do
      post type_configuration_copy_copy_path(type_id: type.id, variant_id: variant.id, aspect: "unknown_aspect"),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response).to have_http_status(:not_found)
      expect(variant.reload.read_attribute(:attribute_groups)).to be_empty
    end

    it "requires admin" do
      login_as create(:user)

      post type_configuration_copy_copy_path(type_id: type.id, variant_id: variant.id, aspect:),
           params: { source_id: source.id },
           as: :turbo_stream

      expect(response).not_to be_successful
      expect(variant.reload.read_attribute(:attribute_groups)).to be_empty
    end
  end
end
