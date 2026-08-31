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

RSpec.describe Workflows::Copies::FromRolesController do
  shared_let(:admin) { create(:admin) }
  shared_let(:source_type) { create(:type, name: "Bug") }
  shared_let(:roles) { create_list(:project_role, 2) }

  current_user { admin }

  describe "#create" do
    let(:source_variant) { source_type.default_variant }
    let(:source_role) { roles.first }
    let(:target_roles) { roles }

    before do
      allow(Workflow).to receive(:copy)

      post :create, params: {
        type_id: source_type.id.to_s,
        source_role_id: source_role.id.to_s,
        target_role_ids: target_roles.map { |role| role.id.to_s }
      }, format: :turbo_stream
    end

    it "copies from the source variant onto itself for every target role" do
      expect(Workflow).to have_received(:copy).exactly(1).time
      expect(Workflow)
        .to have_received(:copy)
              .with(source_variant, source_role, [source_variant], a_collection_containing_exactly(*target_roles))
    end

    it "points the matrix frame at the target roles with a flash notice" do
      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "flash", target: "op-primer-flash-component")
      expect(response.body).to include("Successfully copied workflow to #{target_roles.size} roles.")
      expect(response).to have_turbo_stream(action: "turbo_frame_set_src", target: "workflow-table")
    end
  end
end
