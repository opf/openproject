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
    shared_let(:variant) { create(:type).default_variant }
    shared_let(:role_target) { create(:project_role) }
    shared_let(:variant_target) { create(:type).default_variant }
    shared_let(:role_target2) { create(:project_role) }
    shared_let(:variant_target2) { create(:type).default_variant }

    shared_examples_for "copied workflow" do
      let(:expected_variant) { variant_target }
      let(:expected_role) { role_target }

      it { expect(subject.old_status).to eq(workflow_src.old_status) }

      it { expect(subject.new_status).to eq(workflow_src.new_status) }

      it { expect(expected_variant.workflow_id).to eq(subject.workflow_id) }

      it { expect(subject.role).to eq(expected_role) }

      it { expect(subject.author).to eq(workflow_src.author) }

      it { expect(subject.assignee).to eq(workflow_src.assignee) }
    end

    context "for a workflow w/o author or assignee" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               type_variant: variant,
               role:)
      end

      before { described_class.copy(variant, role, variant_target, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "for a workflow with author" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               type_variant: variant,
               role:,
               author: true)
      end

      before { described_class.copy(variant, role, variant_target, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "for a workflow with assignee" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               type_variant: variant,
               role:,
               assignee: true)
      end

      before { described_class.copy(variant, role, variant_target, role_target) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("id DESC")).first }
      end
    end

    context "when copying to multiple types and roles" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               type_variant: variant,
               role:)
      end

      before { described_class.copy(variant, role, [variant_target, variant_target2], [role_target, role_target2]) }

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).first }

        let(:expected_role) { role_target2 }
        let(:expected_variant) { variant_target2 }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).second }

        let(:expected_role) { role_target }
        let(:expected_variant) { variant_target2 }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).third }

        let(:expected_role) { role_target2 }
        let(:expected_variant) { variant_target }
      end

      it_behaves_like "copied workflow" do
        subject { described_class.order(Arel.sql("workflow_id DESC, role_id DESC")).fourth }

        let(:expected_role) { role_target }
        let(:expected_variant) { variant_target }
      end
    end

    context "when copying from one role to another of the same variant" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               type_variant: variant,
               role:)
      end

      let!(:original_workflow_id) { variant.workflow_id }

      before { described_class.copy(variant, role, [variant], [role_target]) }

      it "keeps the variant on its workflow" do
        expect(variant.reload.workflow_id).to eq(original_workflow_id)
      end

      it "keeps the transitions of the source role" do
        expect(described_class.where(workflow_id: variant.workflow_id, role_id: role.id).pluck(:id))
          .to contain_exactly(workflow_src.id)
      end

      it "copies the transitions onto the target role" do
        expect(described_class.where(workflow_id: variant.workflow_id, role_id: role_target.id)
                              .pluck(:old_status_id, :new_status_id))
          .to contain_exactly([status0.id, status1.id])
      end
    end

    context "when a target variant shares the source's workflow" do
      let!(:workflow_src) do
        create(:status_transition,
               old_status: status0,
               new_status: status1,
               type_variant: variant,
               role:)
      end

      before do
        variant_target.update!(workflows_source: variant)
        described_class.copy(variant, role, [variant_target], [role_target])
      end

      it "moves the target onto a workflow of its own" do
        expect(variant_target.reload.workflow_id).not_to eq(variant.workflow_id)
      end

      it "leaves the source workflow untouched" do
        expect(described_class.where(workflow_id: variant.workflow_id).pluck(:id))
          .to contain_exactly(workflow_src.id)
      end
    end
  end

  describe "self.eligible_roles" do
    subject { described_class.eligible_roles }

    let!(:project_roles) { create_list(:project_role, 3) }

    before do
      create(:global_role)
    end

    it { is_expected.to match_array(project_roles) }
  end
end
