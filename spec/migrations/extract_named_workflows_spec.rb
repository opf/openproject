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
require Rails.root.join("db/migrate/20260916120000_extract_named_workflows.rb")
require Rails.root.join("db/migrate/20260916140000_drop_workflows_aspect_link.rb")

RSpec.describe ExtractNamedWorkflows, type: :model do
  subject(:migrate_up) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  shared_let(:role) { create(:project_role) }
  shared_let(:old_status) { create(:status) }
  shared_let(:new_status) { create(:status) }

  let(:owner) { create(:type, name: "Bug").default_variant }
  let(:borrower) { create(:type, name: "Task").default_variant }
  let!(:kept) { create(:status_transition, type_variant: owner, role:, old_status:, new_status:) }

  let(:independent) { create(:type, name: "Milestone").default_variant }
  let!(:independent_transition) do
    create(:status_transition, type_variant: independent, role:, old_status:, new_status:)
  end

  let(:unreachable_transition) do
    <<~SQL.squish
      INSERT INTO workflows (type_variant_id, role_id, old_status_id, new_status_id, author, assignee)
      VALUES (#{borrower.id}, #{role.id}, #{old_status.id}, #{new_status.id}, false, false)
    SQL
  end

  before do
    ActiveRecord::Migration.suppress_messages { DropWorkflowsAspectLink.new.down }
    ActiveRecord::Base.connection.execute(
      "UPDATE type_variants SET workflows_source_id = #{owner.id} WHERE id = #{borrower.id}"
    )

    ActiveRecord::Migration.suppress_messages { described_class.new.down }
    ActiveRecord::Base.connection.execute(unreachable_transition)
  end

  after do
    [TypeVariant, Workflow, Workflows::StatusTransition].each(&:reset_column_information)
  end

  def workflow_id_of(variant_id)
    ActiveRecord::Base.connection.select_value("SELECT workflow_id FROM type_variants WHERE id = #{variant_id}")
  end

  def transition_ids_of(workflow_id)
    ActiveRecord::Base.connection
                      .select_values("SELECT id FROM workflows_status_transitions WHERE workflow_id = #{workflow_id}")
  end

  it "points the borrowing variant at the owner's workflow" do
    migrate_up

    expect(workflow_id_of(borrower.id)).to eq(workflow_id_of(owner.id))
  end

  it "drops the transitions the borrowing variant kept from before it was linked" do
    migrate_up

    expect(transition_ids_of(workflow_id_of(owner.id))).to contain_exactly(kept.id)
  end

  it "keeps the transitions of a variant that owns its workflow" do
    migrate_up

    expect(transition_ids_of(workflow_id_of(independent.id))).to contain_exactly(independent_transition.id)
  end
end
