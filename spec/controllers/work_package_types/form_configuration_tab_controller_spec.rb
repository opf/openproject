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

RSpec.describe WorkPackageTypes::FormConfigurationTabController do
  let(:type) { create(:type) }
  let(:user) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  describe "GET #edit" do
    context "with an unauthorized account" do
      let(:user) { create(:user) }

      before { get "edit", params: { type_id: type.id } }

      it { expect(response).to have_http_status(:forbidden) }
    end

    context "with invalid type id" do
      it "renders a 404" do
        get :edit, params: { type_id: "invalid" }
        expect(response).to have_http_status(:not_found)
      end
    end

    it "renders the edit tab" do
      get :edit, params: { type_id: type.id }
      expect(response).to render_template(:edit)
    end
  end

  describe "POST #update" do
    let(:params) do
      {
        type_id: type.id,
        type: {
          attribute_groups: [
            {
              type: "attribute",
              name: "People",
              attributes: [
                { key: "assignee", is_cf: nil, is_required: nil, translation: "Assignee" }
              ],
              query: nil
            }
          ].to_json
        }
      }
    end

    context "without enterprise feature enabled" do
      describe "form is not updated" do
        before { put :update, params: params }

        it { expect(response).to have_http_status(:unprocessable_entity) }
      end
    end

    context "with enterprise feature enabled", with_ee: %i[edit_attribute_groups] do
      context "with an unauthorized account" do
        let(:user) { create(:user) }

        describe "the access should be restricted" do
          before { post "update", params: { type_id: "123" } }

          it { expect(response).to have_http_status(:forbidden) }
        end
      end

      it "updates the work package type" do
        put :update, params: params

        expect(response).to redirect_to(edit_type_form_configuration_path(type))

        type.reload
        expect(type.attribute_groups.count).to eq(1)
        expect(type.attribute_groups.first.key).to eql("People")
      end

      context "with invalid parameters" do
        let(:params) do
          {
            type_id: type.id,
            type: {
              attribute_groups: [
                {
                  type: "attribute",
                  name: "",
                  attributes: [
                    { key: "assignee", is_cf: nil, is_required: nil, translation: "Assignee" }
                  ],
                  query: nil
                }
              ].to_json
            }
          }
        end

        it "renders the edit tab" do
          put :update, params: params

          expect(response).to render_template(:edit)
        end
      end

      context "with malformed attribute group JSON" do
        let(:params) do
          {
            type_id: type.id,
            type: {
              attribute_groups: "{"
            }
          }
        end

        it "renders the edit tab instead of raising" do
          put :update, params: params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:edit)
        end
      end
    end
  end
end
