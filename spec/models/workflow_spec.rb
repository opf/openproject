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

RSpec.describe Workflow do
  shared_let(:role) { create(:project_role) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }

  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  describe "#name" do
    it "is required" do
      expect(described_class.new(name: nil)).not_to be_valid
    end

    it "is limited to 255 characters" do
      workflow = described_class.new(name: "a" * 256)

      expect(workflow).not_to be_valid
      expect(workflow.errors).to be_of_kind(:name, :too_long)
    end

    it "may not repeat another workflow's name, whatever the casing" do
      create(:named_workflow, name: "Standard flow")
      duplicate = described_class.new(name: "standard FLOW")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors).to be_of_kind(:name, :taken)
    end

    it "may repeat a name another scope holds" do
      create(:named_workflow, name: "Standard flow")

      expect(described_class.new(name: "Standard flow", project:)).to be_valid
    end

    it "may not repeat a name the same project already holds" do
      create(:project_owned_workflow, project:, name: "Standard flow")
      duplicate = described_class.new(name: "standard FLOW", project:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors).to be_of_kind(:name, :taken)
    end
  end

  describe "ownership" do
    shared_let(:global) { create(:named_workflow, name: "Global flow") }
    shared_let(:owned) { create(:project_owned_workflow, project:, name: "Ours") }
    shared_let(:foreign) { create(:project_owned_workflow, project: other_project, name: "Theirs") }

    # Every project brings types along, and every type brings a workflow, so the scopes are read
    # through the three this block is about.
    def under_test(scope) = scope.where(id: [global, owned, foreign]).to_a

    it "separates the global workflows from the owned ones" do
      expect(under_test(described_class.global)).to contain_exactly(global)
      expect(under_test(described_class.project_owned)).to contain_exactly(owned, foreign)
    end

    it "answers which project owns a workflow" do
      expect(under_test(described_class.owned_by(project))).to contain_exactly(owned)
      expect(under_test(described_class.owned_by(nil))).to contain_exactly(global)
    end

    it "offers a project the global workflows and its own" do
      expect(under_test(described_class.available_in(project))).to contain_exactly(global, owned)
      expect(under_test(described_class.available_in(nil))).to contain_exactly(global)
    end

    it "is project specific only for a workflow a project owns" do
      expect(owned).to be_project_specific
      expect(global).not_to be_project_specific
    end
  end

  describe ".build_with_available_name" do
    it "keeps the name it is given while it is free" do
      expect(described_class.build_with_available_name("Bug").name).to eq("Bug")
    end

    it "steps past a name already taken, whatever the casing" do
      create(:named_workflow, name: "Bug")

      expect(described_class.build_with_available_name("bug").name).to eq("bug (2)")
    end

    it "keeps stepping until it finds a free one" do
      create(:named_workflow, name: "Bug")
      create(:named_workflow, name: "Bug (2)")

      expect(described_class.build_with_available_name("Bug").name).to eq("Bug (3)")
    end

    it "builds the workflow for the project it is given" do
      workflow = described_class.build_with_available_name("Bug", project:)

      expect(workflow.project).to eq(project)
      expect(workflow).to be_project_specific
    end

    it "only steps past a name the same scope holds" do
      create(:named_workflow, name: "Bug")

      expect(described_class.build_with_available_name("Bug", project:).name).to eq("Bug")
      expect(described_class.build_with_available_name("Bug").name).to eq("Bug (2)")
    end
  end

  describe "#used_by_one_variant?" do
    shared_let(:type) { create(:type) }

    it "is true while a single variant references it" do
      expect(type.default_variant.workflow).to be_used_by_one_variant
    end

    it "is false once another variant references it too" do
      create(:type).default_variant.update!(workflow: type.default_variant.workflow)

      expect(type.default_variant.workflow.reload).not_to be_used_by_one_variant
    end
  end

  describe "deletion" do
    it "is refused while a variant still references it" do
      workflow = create(:type).default_variant.workflow

      expect(workflow.destroy).to be_falsey
      expect(workflow.errors).to be_of_kind(:base, :"restrict_dependent_destroy.has_many")
    end

    it "takes its transitions with it once nothing references it" do
      workflow = create(:named_workflow)
      create(:workflow, workflow:, role:, old_status: status_a, new_status: status_b)

      expect { workflow.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe "#statuses" do
    shared_let(:workflow) { create(:named_workflow) }

    it "spans both ends of every transition" do
      create(:workflow, workflow:, role:, old_status: status_a, new_status: status_b)

      expect(workflow.statuses).to contain_exactly(status_a, status_b)
    end

    it "is narrowed to a role when one is given" do
      other_role = create(:project_role)
      create(:workflow, workflow:, role:, old_status: status_a, new_status: status_b)

      expect(workflow.statuses(role: other_role)).to be_empty
      expect(workflow.statuses(role:)).to contain_exactly(status_a, status_b)
    end

    it "is narrowed to the tab when one is given" do
      create(:workflow, workflow:, role:, old_status: status_a, new_status: status_b, author: true)

      expect(workflow.statuses(tab: "author")).to contain_exactly(status_a, status_b)
      expect(workflow.statuses(tab: "always")).to be_empty
    end
  end

  describe "#statuses_missing_in" do
    shared_let(:workflow) { create(:named_workflow) }
    shared_let(:other) { create(:named_workflow) }
    shared_let(:status_c) { create(:status) }
    shared_let(:hidden_role) { create(:work_package_role) }

    let(:roles) { Role.where(id: role) }

    before do
      create(:status_transition, workflow:, role:, old_status: status_a, new_status: status_b)
      create(:status_transition, workflow:, role: hidden_role, old_status: status_a, new_status: status_c)
    end

    it "lists what the given roles use here and not in the other, ignoring what only the other has" do
      create(:status_transition, workflow: other, role:, old_status: status_a, new_status: status_c)

      expect(workflow.statuses_missing_in(other, roles:)).to contain_exactly(status_b)
    end

    it "ignores the statuses the other workflow reaches only through roles outside the given ones" do
      create(:status_transition, workflow: other, role: hidden_role, old_status: status_a, new_status: status_b)

      expect(workflow.statuses_missing_in(other, roles:)).to contain_exactly(status_a, status_b)
    end
  end

  describe "when the owning project is deleted" do
    let(:doomed) { create(:project) }

    it "takes its own workflows with it and leaves the global ones" do
      owned_id = create(:project_owned_workflow, project: doomed).id
      global_id = create(:named_workflow, name: "Stays global").id

      doomed.destroy!

      expect(described_class.where(id: owned_id)).to be_empty
      expect(described_class.where(id: global_id)).to be_present
    end

    # Both the variants and the workflows cascade from the project, while a variant restricts the
    # deletion of the workflow it references.
    it "removes a variant and the workflow that variant owns in one go" do
      variant = create(:project_owned_type_variant, project: doomed)
      variant.update!(workflow: create(:project_owned_workflow, project: doomed))
      variant_id = variant.id
      workflow_id = variant.workflow_id

      expect { doomed.destroy! }.not_to raise_error

      expect(TypeVariant.where(id: variant_id)).to be_empty
      expect(described_class.where(id: workflow_id)).to be_empty
    end
  end
end
