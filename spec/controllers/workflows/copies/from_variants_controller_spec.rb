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

RSpec.describe Workflows::Copies::FromVariantsController do
  shared_let(:admin) { create(:admin) }
  shared_let(:source_type) { create(:type, name: "Bug") }
  shared_let(:source_variant) { create(:type_variant, type: source_type, variant_name: "Mobile") }
  shared_let(:target_variants) { create_list(:type_variant, 2) }

  current_user { admin }

  describe "#create" do
    let(:target_variant_ids) { target_variants.map { |variant| variant.id.to_s } }

    before do
      allow(Workflow).to receive(:copy)

      post :create, params: {
        type_id: source_type.id.to_s,
        variant_id: source_variant.id.to_s,
        target_variant_ids:
      }, format: :turbo_stream
    end

    it "copies from the source variant onto every target, for the eligible roles" do
      expect(Workflow)
        .to have_received(:copy)
              .with(source_variant, nil, a_collection_containing_exactly(*target_variants), Workflow.eligible_roles)
    end

    it "redirects to the first target's workflow tab with a flash notice" do
      target = target_variants.first

      expect(response)
        .to redirect_to(edit_type_workflow_path(type_id: target.type_id, variant_id: target.id))
      expect(flash[:notice]).to eq("Successfully copied workflow to 2 types.")
    end
  end

  context "without a source variant" do
    before do
      post :create, params: {
        type_id: source_type.id.to_s,
        variant_id: "0",
        target_variant_ids: target_variants.map { |variant| variant.id.to_s }
      }, format: :turbo_stream
    end

    it "refuses the copy" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "without any target" do
    before do
      post :create, params: {
        type_id: source_type.id.to_s,
        variant_id: source_variant.id.to_s,
        target_variant_ids: []
      }, format: :turbo_stream
    end

    it "refuses the copy" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
