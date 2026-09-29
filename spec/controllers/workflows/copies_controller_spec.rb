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

RSpec.describe Workflows::CopiesController do
  shared_let(:admin) { create(:admin) }
  shared_let(:source_type) { create(:type, name: "Bug") }
  shared_let(:other_type) { create(:type, name: "Feature") }
  shared_let(:other_variant) { create(:type_variant, type: other_type, variant_name: "Mobile") }

  current_user { admin }

  describe "#new" do
    let(:source_role) { nil }
    let(:params) { { type_id: source_type.id.to_s, source_role_id: source_role&.id } }

    before do
      get :new, params:, format: :turbo_stream
    end

    it "is a success" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the correct template" do
      expect(response).to render_template :new
    end

    it "assigns the type's base variant as the source" do
      expect(assigns[:source_variant]).to eq(source_type.default_variant)
    end

    it "does not assign any source role" do
      expect(assigns[:source_role]).to be_nil
    end

    it "assigns the eligible roles" do
      expect(assigns[:all_roles]).to match_array(Workflow.eligible_roles)
    end

    context "with variants switched off", with_flag: { type_variants: false } do
      it "offers only base variants, excluding the source" do
        expect(assigns[:other_variants]).to contain_exactly(other_type.default_variant)
      end
    end

    context "with variants switched on", with_flag: { type_variants: true } do
      it "offers every variant, excluding the source" do
        expect(assigns[:other_variants])
          .to contain_exactly(other_type.default_variant, other_variant)
      end
    end

    context "when a variant is addressed directly", with_flag: { type_variants: true } do
      let(:params) { { type_id: other_type.id.to_s, variant_id: other_variant.id.to_s } }

      it "assigns that variant as the source and leaves it out of the targets" do
        expect(assigns[:source_variant]).to eq(other_variant)
        expect(assigns[:other_variants]).not_to include(other_variant)
      end
    end

    context "when the source role is specified" do
      let(:source_role) { Workflow.eligible_roles.first }

      it "assigns the source role" do
        expect(assigns[:source_role]).to eq(source_role)
      end
    end
  end
end
