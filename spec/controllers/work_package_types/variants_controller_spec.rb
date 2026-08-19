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

RSpec.describe WorkPackageTypes::VariantsController, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type) }

  before { login_as user }

  context "with admin access" do
    let(:user) { admin }

    describe "POST make_default" do
      context "for the base variant" do
        let(:variant) { type.default_variant }

        before { post :make_default, params: { type_id: type.id, id: variant.id } }

        it "marks it as the one new projects start with" do
          expect(response).to redirect_to(types_path)
          expect(variant.reload).to be_enabled_in_new_projects
        end
      end

      context "for a named variant" do
        let!(:variant) { create(:type_variant, type:) }

        before { post :make_default, params: { type_id: type.id, id: variant.id } }

        it "marks it too: either variant of a type can be the one new projects start with" do
          expect(response).to redirect_to(types_path)
          expect(variant.reload).to be_enabled_in_new_projects
        end
      end

      context "for a variant of another type" do
        let(:other_variant) { create(:type).default_variant }

        before { post :make_default, params: { type_id: type.id, id: other_variant.id } }

        it "does not find it, so the flag stays put" do
          expect(response).to have_http_status(:not_found)
          expect(other_variant.reload).not_to be_enabled_in_new_projects
        end
      end
    end

    describe "POST remove_default" do
      let(:type) { create(:type, default_variant_enabled_in_all_projects: true) }
      let(:variant) { type.default_variant }

      before { post :remove_default, params: { type_id: type.id, id: variant.id } }

      it "clears the flag" do
        expect(response).to redirect_to(types_path)
        expect(variant.reload).not_to be_enabled_in_new_projects
      end
    end
  end

  context "without admin access" do
    let(:user) { create(:user) }
    let(:variant) { type.default_variant }

    describe "POST make_default" do
      before { post :make_default, params: { type_id: type.id, id: variant.id } }

      it "is forbidden and leaves the flag untouched" do
        expect(response).to have_http_status(:forbidden)
        expect(variant.reload).not_to be_enabled_in_new_projects
      end
    end
  end
end
