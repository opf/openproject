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

RSpec.describe WorkflowsController do
  let!(:role_scope) do
    role_scope = instance_double(ActiveRecord::Relation)

    allow(Role)
      .to receive(:where)
            .with(type: ProjectRole.name)
            .and_return(role_scope)

    allow(role_scope)
      .to receive_messages(order: role_scope, find_by: nil, first: role)

    allow(role_scope)
      .to receive(:find)
            .with(role.id.to_s)
            .and_return(role)

    allow(role_scope)
      .to receive(:find_by)
            .with(id: role.id.to_s)
            .and_return(role)

    allow(role_scope)
      .to receive(:where)
            .with(id: nil)
            .and_return([])

    role_scope
  end

  let!(:role) do
    build_stubbed(:project_role)
  end
  let!(:type) do
    build_stubbed(:type) do |t|
      allow(Type)
        .to receive(:find)
              .with(t.id.to_s)
              .and_return(t)

      allow(Type)
        .to receive(:find_by)
              .and_return(nil)

      allow(Type)
        .to receive(:find_by)
              .with(id: t.id.to_s)
              .and_return(t)
    end
  end

  current_user { build_stubbed(:admin) }

  describe "#edit" do
    let(:non_type_status) { build_stubbed(:status) }
    let(:type_status) { build_stubbed(:status) }

    before do
      allow(type)
        .to receive(:statuses)
              .and_return [type_status]

      allow(Status)
        .to receive(:all)
              .and_return [type_status, non_type_status]
    end

    context "without parameters" do
      before do
        get :edit, params: { type_id: type.id.to_s }
      end

      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the edit template" do
        expect(response)
          .to render_template :edit
      end

      it "assigns @roles as the canonical collection" do
        expect(assigns[:roles]).to contain_exactly(role)
      end

      it "does assign type" do
        expect(assigns[:type])
          .to eq type
      end
    end

    context "with a single role param" do
      before do
        allow(role_scope)
          .to receive(:where)
                .with(id: [role.id.to_s])
                .and_return([role])

        get :edit, params: { role_ids: [role.id.to_s], type_id: type.id.to_s }
      end

      it "is successful" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the edit template" do
        expect(response).to render_template :edit
      end

      it "assigns the selected role" do
        expect(assigns[:roles]).to contain_exactly(role)
      end

      it "assigns type" do
        expect(assigns[:type]).to eq type
      end
    end

    context "with multiple role params" do
      let(:role2) { build_stubbed(:project_role) }

      before do
        allow(role_scope)
          .to receive(:where)
                .with(id: [role.id.to_s, role2.id.to_s])
                .and_return([role, role2])

        get :edit, params: { role_ids: [role.id.to_s, role2.id.to_s], type_id: type.id.to_s }
      end

      it "is successful" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the edit template" do
        expect(response).to render_template :edit
      end

      it "assigns all selected roles" do
        expect(assigns[:roles]).to contain_exactly(role, role2)
      end

      it "assigns type" do
        expect(assigns[:type]).to eq type
      end
    end
  end
end
