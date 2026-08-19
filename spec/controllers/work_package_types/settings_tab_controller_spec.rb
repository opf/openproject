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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackageTypes::SettingsTabController do
  let(:type) { create(:type_bug) }

  before do
    login_as user
  end

  context "without admin access" do
    let(:user) { create :user }

    describe "GET edit" do
      before do
        get :edit, params: { type_id: type.id }
      end

      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  context "with admin access" do
    let(:user) { create :admin }

    describe "GET edit" do
      before do
        get :edit, params: { type_id: type.id }
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template "edit" }
    end

    describe "PUT update" do
      let(:lightsaber_red) { create(:color, name: "Lightsaber-Red") }
      let(:params) do
        {
          "type_id" => type.id,
          "type" => {
            "name" => "Galactic Order",
            "color_id" => lightsaber_red.id.to_s,
            "description" => "This is how the emperor governs you ... yes you!",
            "is_milestone" => "0",
            "is_in_roadmap" => "1",
            "is_default" => "0"
          }
        }
      end

      before do
        put :update, params:
      end

      it { expect(response).to redirect_to(edit_type_settings_path(type_id: type.id)) }

      context "if the the params are invalid" do
        let(:another_type) { create(:type_feature) }
        let(:params) do
          {
            "type_id" => type.id,
            "type" => {
              "name" => another_type.name
            }
          }
        end

        before do
          another_type
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }
        it { expect(response).to render_template "edit" }
      end
    end
  end
end
