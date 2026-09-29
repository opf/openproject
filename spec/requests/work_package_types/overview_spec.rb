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

RSpec.describe "The overview of a work package type",
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

  before { login_as admin }

  it "serves the overview of a type" do
    get type_settings_path(type_id: type.id)

    expect(response).to have_http_status(:ok)
  end

  it "serves the overview of a named variant" do
    get type_settings_path(**variant.path_args)

    expect(response).to have_http_status(:ok)
  end

  it "refuses a user who is not an administrator" do
    login_as create(:user)

    get type_settings_path(type_id: type.id)

    expect(response).not_to have_http_status(:ok)
  end

  context "when the variants feature is disabled", with_flag: { type_variants: false } do
    it "hands the landing page back to the details tab" do
      get type_settings_path(type_id: type.id)

      expect(response).to redirect_to(edit_type_details_path(type_id: type.id))
    end

    it "hands a named variant's landing page back to its details tab" do
      get type_settings_path(**variant.path_args)

      expect(response).to redirect_to(edit_type_details_path(**variant.path_args))
    end
  end

  context "when a project owns the variant" do
    shared_let(:project) { create(:project) }
    shared_let(:owned) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
    shared_let(:project_admin) do
      create(:user, member_with_permissions: { project => %i[manage_project_variants] })
    end

    before { login_as project_admin }

    it "serves the overview to a member who may manage the project's variants" do
      get type_settings_path(**owned.path_args)

      expect(response).to have_http_status(:ok)
    end

    context "when the variants feature is disabled", with_flag: { type_variants: false } do
      it "has no such page" do
        get type_settings_path(**owned.path_args)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
