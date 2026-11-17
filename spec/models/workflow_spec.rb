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

RSpec.describe Workflow do
  shared_let(:role) { create(:project_role) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }

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
  end

  describe ".available_name" do
    it "keeps the name it is given while it is free" do
      expect(described_class.available_name("Bug")).to eq("Bug")
    end

    it "steps past a name already taken, whatever the casing" do
      create(:named_workflow, name: "Bug")

      expect(described_class.available_name("bug")).to eq("bug (2)")
    end

    it "keeps stepping until it finds a free one" do
      create(:named_workflow, name: "Bug")
      create(:named_workflow, name: "Bug (2)")

      expect(described_class.available_name("Bug")).to eq("Bug (3)")
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

  describe "#in_use?" do
    it "is true while a variant references it" do
      expect(create(:type).default_variant.workflow).to be_in_use
    end

    it "is false once nothing references it" do
      expect(create(:named_workflow)).not_to be_in_use
    end
  end

  describe "#replacement_targets" do
    it "offers the other workflows" do
      workflow = create(:named_workflow)
      other = create(:named_workflow)

      expect(workflow.replacement_targets).to include(other)
    end

    it "excludes itself" do
      workflow = create(:named_workflow)

      expect(workflow.replacement_targets).not_to include(workflow)
    end
  end
end
