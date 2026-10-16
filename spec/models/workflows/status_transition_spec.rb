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

RSpec.describe Workflows::StatusTransition do
  describe ".copy" do
    shared_let(:status0) { create(:status) }
    shared_let(:status1) { create(:status) }
    shared_let(:role) { create(:project_role) }
    shared_let(:source_workflow) { create(:named_workflow) }
    shared_let(:role_target) { create(:project_role) }
    shared_let(:target_workflow) { create(:named_workflow) }
    shared_let(:role_target2) { create(:project_role) }
    shared_let(:target_workflow2) { create(:named_workflow) }

    shared_examples_for "copied workflow" do
      let(:expected_workflow) { target_workflow }
      let(:expected_role) { role_target }

      it { expect(subject.old_status).to eq(workflow_src.old_status) }

      it { expect(subject.new_status).to eq(workflow_src.new_status) }

      it { expect(subject.workflow).to eq(expected_workflow) }

      it { expect(subject.role).to eq(expected_role) }

      it { expect(subject.author).to eq(workflow_src.author) }

      it { expect(subject.assignee).to eq(workflow_src.assignee) }
    end

    context "for a workflow w/o author or assignee" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               workflow: source_workflow,
               role:)
      end

      before { described_class.copy(source_workflow, role, target_workflow, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "for a workflow with author" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               workflow: source_workflow,
               role:,
               author: true)
      end

      before { described_class.copy(source_workflow, role, target_workflow, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "for a workflow with assignee" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               workflow: source_workflow,
               role:,
               assignee: true)
      end

      before { described_class.copy(source_workflow, role, target_workflow, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "when copying to multiple types and roles" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               workflow: source_workflow,
               role:)
      end

      before { described_class.copy(source_workflow, role, [target_workflow, target_workflow2], [role_target, role_target2]) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).first }

        let(:expected_role) { role_target2 }
        let(:expected_workflow) { target_workflow2 }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).second }

        let(:expected_role) { role_target }
        let(:expected_workflow) { target_workflow2 }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).third }

        let(:expected_role) { role_target2 }
        let(:expected_workflow) { target_workflow }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).fourth }

        let(:expected_role) { role_target }
        let(:expected_workflow) { target_workflow }
      end
    end

    context "when copying from one role to another of the same workflow" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               workflow: source_workflow,
               role:)
      end

      before { described_class.copy(source_workflow, role, [source_workflow], [role_target]) }

      it "keeps the transitions of the source role" do
        expect(described_class.where(workflow: source_workflow, role_id: role.id).pluck(:id))
          .to contain_exactly(workflow_src.id)
      end

      it "copies the transitions onto the target role" do
        expect(described_class.where(workflow: source_workflow, role_id: role_target.id)
                              .pluck(:old_status_id, :new_status_id))
          .to contain_exactly([status0.id, status1.id])
      end
    end
  end
end
