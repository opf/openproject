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
  let!(:source_type) do
    build_stubbed(:type) do |stub|
      allow(Type)
        .to receive(:find_by)
              .with(id: stub.id.to_s)
              .and_return(stub)
    end
  end

  let!(:eligible_roles) do
    instance_double(ActiveRecord::Relation, to_a: all_roles).tap do |relation|
      allow(Role)
        .to receive(:where)
              .with(type: ProjectRole.name)
              .and_return(relation)
    end
  end

  let!(:all_roles) do
    build_stubbed_list(:project_role, 2)
  end

  before do
    allow(eligible_roles).to receive(:find_by).and_return(source_role)
  end

  current_user { build_stubbed(:admin) }

  describe "#create" do
    let!(:source_role) { all_roles.sample }
    let!(:target_roles) do
      all_roles.tap do |stubs|
        allow(eligible_roles)
          .to receive(:where).with(id: target_role_ids)
            .and_return(stubs)
      end
    end
    let!(:target_role_ids) { all_roles.map { |role| role.id.to_s } }

    before do
      allow(Workflow).to receive(:copy)

      post :create, params: {
        workflow_type_id: source_type.id.to_s,
        source_role_id: source_role.id.to_s,
        target_role_ids: target_role_ids
      }, format: :turbo_stream
    end

    it "calls the Workflow.copy method with every target role" do
      expect(Workflow)
        .to have_received(:copy).exactly(1).times
      expect(Workflow)
        .to have_received(:copy)
              .with(source_type, source_role, [source_type], target_roles)
    end

    it "redirects with a flash notice" do
      expect(response).to redirect_to(edit_workflow_path(source_type, role_id: target_roles.first.id))
      expect(flash[:notice]).to eq("Successfully copied workflow to 2 roles.")
    end
  end
end
