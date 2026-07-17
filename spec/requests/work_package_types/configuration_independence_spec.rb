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

RSpec.describe "Work package type configuration independence",
               :skip_csrf,
               type: :rails_request,
               with_flag: { subtypes: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:source) { create(:type) }

  before { login_as admin }

  describe "GET dialog" do
    it "renders the independent mode picker with the aspect's modes" do
      get type_configuration_independence_dialog_path(type_id: type.id, aspect: Type::ConfigurationLink::FORM_CONFIGURATION),
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Independent mode")
      expect(response.body).to include("Copy from linked")
      expect(response.body).to include("Default settings")
      expect(response.body).not_to include("Empty")
    end

    it "offers copy and empty for patterns" do
      get type_configuration_independence_dialog_path(type_id: type.id, aspect: Type::ConfigurationLink::PATTERNS),
          as: :turbo_stream

      expect(response.body).to include("Copy from linked")
      expect(response.body).to include("Empty")
      expect(response.body).not_to include("Default settings")
    end

    it "is not found for an unknown aspect" do
      get type_configuration_independence_dialog_path(type_id: type.id, aspect: "not_an_aspect"), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "is not found when the subtypes feature is disabled", with_flag: { subtypes: false } do
      get type_configuration_independence_dialog_path(type_id: type.id, aspect: Type::ConfigurationLink::PATTERNS),
          as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST confirm" do
    it "closes the picker and renders the danger confirmation" do
      post type_configuration_independence_confirm_path(type_id: type.id, aspect: Type::ConfigurationLink::PATTERNS),
           params: { mode: WorkPackageTypes::IndependentMode::EMPTY },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("closeDialog")
      expect(response.body).to include("Switch configuration mode?")
      expect(response.body).to include("I understand that this will override the current settings")
    end

    it "flashes an error for a mode the aspect does not offer" do
      post type_configuration_independence_confirm_path(type_id: type.id, aspect: Type::ConfigurationLink::PATTERNS),
           params: { mode: WorkPackageTypes::IndependentMode::DEFAULT },
           as: :turbo_stream

      expect(response.body).not_to include("Switch configuration mode?")
      expect(response.body).to include(I18n.t("types.edit.reuse_mode.independent.invalid_mode"))
    end
  end

  describe "POST switch" do
    let(:aspect) { Type::ConfigurationLink::PATTERNS }

    it "switches to independent, severs the link and reloads the frame" do
      type.link!(aspect, source:)

      post type_configuration_independence_switch_path(type_id: type.id, aspect:),
           params: { mode: WorkPackageTypes::IndependentMode::EMPTY },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(type.reload).not_to be_linked(aspect)
      expect(response.body).to include("closeDialog")
      expect(response.body).to include("dispatchEvent")
      expect(response.body)
        .to include(WorkPackageTypes::ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME)
      expect(response.body).to include(I18n.t("types.edit.reuse_mode.independent.success"))
    end

    it "flashes an error and keeps the link for an unavailable mode" do
      type.link!(aspect, source:)

      post type_configuration_independence_switch_path(type_id: type.id, aspect:),
           params: { mode: WorkPackageTypes::IndependentMode::DEFAULT },
           as: :turbo_stream

      expect(response.body).not_to include("dispatchEvent")
      expect(type.reload).to be_linked(aspect)
    end

    it "requires admin" do
      login_as create(:user)
      type.link!(aspect, source:)

      post type_configuration_independence_switch_path(type_id: type.id, aspect:),
           params: { mode: WorkPackageTypes::IndependentMode::EMPTY },
           as: :turbo_stream

      expect(response).not_to be_successful
      expect(type.reload).to be_linked(aspect)
    end
  end
end
