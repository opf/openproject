# frozen_string_literal: true

# -- copyright
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
# ++

require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples "work package contract with backlogs extensions" do
  include_context "ModelContract shared context"
  let(:work_package_type) { build_stubbed(:type) }
  let(:work_package_status) { build_stubbed(:status) }
  let(:work_package_priority) { build_stubbed(:priority) }
  let(:work_package_author) { build_stubbed(:user) }
  let(:work_package_story_points) { 5 }
  let(:work_package_sprint) { build_stubbed(:sprint) }
  let(:work_package_position) { 5 }
  let(:assignable_sprints) { [work_package_sprint] }
  let(:backlogs_enabled) { true }
  let(:work_package_project) do
    build_stubbed(:project, types: [work_package_type]) do |project|
      allow(project).to receive(:backlogs_enabled?).and_return(backlogs_enabled)
    end
  end
  let(:user) do
    build_stubbed(:user) do |user|
      mock_permissions_for(user) do |mock|
        mock.allow_in_project *effective_permissions, project: work_package_project
      end
    end
  end

  subject(:contract) { described_class.new(work_package, user) }

  let(:effective_permissions) { permissions }

  before do
    assignable_sprints_scope = instance_double(ActiveRecord::Relation)

    allow(Sprint)
      .to receive(:assignable)
            .with(project: work_package.project, user:)
            .and_return(assignable_sprints_scope)

    allow(assignable_sprints_scope)
      .to receive(:exists?) do |id:|
      assignable_sprints.map(&:id).include?(id.to_i)
    end
  end

  describe "validations" do
    context "when all attributes are valid" do
      it_behaves_like "contract is valid"
    end

    context "when story points are empty" do
      let(:work_package_story_points) { nil }

      it_behaves_like "contract is valid"
    end

    context "when story points are 0" do
      let(:work_package_story_points) { 0 }

      it_behaves_like "contract is valid"
    end

    context "when story points are negative" do
      let(:work_package_story_points) { -1 }

      it_behaves_like "contract is invalid", story_points: :greater_than_or_equal_to
    end

    context "when story points are larger than 10000" do
      let(:work_package_story_points) { 10001 }

      it_behaves_like "contract is invalid", story_points: :less_than
    end

    context "when story points are floats" do
      let(:work_package_story_points) { 1.1 }

      it_behaves_like "contract is invalid", story_points: :not_an_integer
    end

    context "when changing story points with backlogs being disabled" do
      let(:backlogs_enabled) { false }

      it_behaves_like "contract is invalid", story_points: :error_readonly
    end

    context "when sprint is set to nil" do
      let(:work_package_sprint) { nil }

      it_behaves_like "contract is valid"
    end

    context "when sprint is set to a sprint not assignable" do
      let(:assignable_sprints) { [] }

      it_behaves_like "contract is invalid", sprint: :not_assignable
    end

    context "when sprint is set while the user lacks the :manage_sprint_items permission" do
      let(:effective_permissions) { permissions - [:manage_sprint_items] }

      it_behaves_like "contract is invalid", sprint_id: :error_readonly
    end

    context "when backlog_bucket is set while the user lacks the :manage_sprint_items permission" do
      let(:effective_permissions) { permissions - [:manage_sprint_items] }

      before do
        work_package.sprint = nil
        work_package.backlog_bucket = build_stubbed(:backlog_bucket, project: work_package_project)
      end

      it_behaves_like "contract is invalid", backlog_bucket_id: :error_readonly
    end

    context "when position is written by the user" do
      before do
        work_package.position = work_package_position
      end

      it_behaves_like "contract is invalid", position: :error_readonly
    end

    describe "when attaching to a backlog bucket" do
      before do
        work_package.backlog_bucket = backlog_bucket
      end

      context "when only backlog bucket is set" do
        let(:work_package_sprint) { nil }
        let(:backlog_bucket) { build_stubbed(:backlog_bucket, project: work_package_project) }

        it_behaves_like "contract is valid"
      end

      context "when both sprint and backlog bucket are set" do
        let(:backlog_bucket) { build_stubbed(:backlog_bucket, project: work_package_project) }

        it_behaves_like "contract is invalid", base: :backlog_bucket_xor_sprint
      end

      context "when backlog bucket belongs to a different project" do
        let(:work_package_sprint) { nil }
        let(:backlog_bucket) { build_stubbed(:backlog_bucket, project: build_stubbed(:project)) }

        it_behaves_like "contract is invalid", backlog_bucket: :backlog_bucket_from_another_project
      end
    end
  end

  describe "writable_attributes" do
    it "includes sprint, backlog_bucket and story_points", :aggregate_failures do
      expect(contract.writable_attributes).to include("story_points", "backlog_bucket", "sprint")
      expect(contract.writable_attributes).not_to include("position")
    end

    context "when the user lacks the :manage_sprint_items permission" do
      let(:effective_permissions) { permissions - [:manage_sprint_items] }

      it "includes story_points but lacks sprint and backlog_bucket", :aggregate_failures do
        expect(contract.writable_attributes).to include("story_points")
        expect(contract.writable_attributes).not_to include("backlog_bucket", "sprint", "position")
      end
    end

    context "when backlogs is deactivated" do
      let(:backlogs_enabled) { false }
      # Removing the permission here as this is what will happen when deactivating backlogs.
      # Otherwise, the production would need to have a superfluous check.
      let(:effective_permissions) { permissions - [:manage_sprint_items] }

      it "includes none of the backlogs attributes", :aggregate_failures do
        expect(contract.writable_attributes).not_to include("story_points", "backlog_bucket", "sprint", "position")
      end
    end
  end
end
