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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("db/migrate/20261028100000_remove_project_owned_workflows")

RSpec.describe RemoveProjectOwnedWorkflows, type: :model do
  let(:conn) { ActiveRecord::Base.connection }
  let(:project) { create(:project) }
  let(:type) { create(:type, name: "Bug") }
  let(:default_workflow) { type.default_variant.workflow }
  let(:global_workflow) { create(:named_workflow, name: "Release flow") }
  let(:owned_workflow) { create(:named_workflow, name: "Bookshop flow") }
  let(:variant) { create(:project_owned_type_variant, type:, project:, variant_name: "Bookshop") }
  let(:other_variant) { create(:project_owned_type_variant, type:, project:, variant_name: "Shared") }

  def migrate(direction)
    ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }
    Workflow.reset_column_information
  end

  def own(workflow)
    conn.execute("UPDATE workflows SET project_id = #{project.id} WHERE id = #{workflow.id}")
  end

  before do
    migrate(:down)

    own(owned_workflow)
    variant.update_column(:workflow_id, owned_workflow.id)
    other_variant.update_column(:workflow_id, global_workflow.id)
    create(:status_transition, workflow: owned_workflow)
  end

  after do
    migrate(:up) if conn.column_exists?(:workflows, :project_id)
  end

  it "moves the variants of a project workflow to the workflow of their type's default variant" do
    migrate(:up)

    expect(variant.reload.workflow).to eq(default_workflow)
  end

  it "keeps the variants that use a global workflow on it" do
    migrate(:up)

    expect(other_variant.reload.workflow).to eq(global_workflow)
  end

  it "deletes the project workflows and their transitions", :aggregate_failures do
    migrate(:up)

    expect(Workflow.where(id: owned_workflow.id)).to be_empty
    expect(Workflows::StatusTransition.where(workflow_id: owned_workflow.id)).to be_empty
    expect(Workflow.where(id: [global_workflow.id, default_workflow.id]).count).to eq(2)
  end

  it "removes the owning project" do
    migrate(:up)

    expect(conn.column_exists?(:workflows, :project_id)).to be(false)
  end

  it "keeps the names of all workflows unique, whatever the casing" do
    migrate(:up)

    insert = "INSERT INTO workflows (name, created_at, updated_at) VALUES ('release FLOW', NOW(), NOW())"

    expect { conn.transaction(requires_new: true) { conn.execute(insert) } }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
