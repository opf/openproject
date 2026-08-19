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

RSpec.describe Workflows::MatrixContext do
  shared_let(:variant) { create(:type).default_variant }
  shared_let(:role) { create(:project_role) }
  shared_let(:other_role) { create(:project_role) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }
  shared_let(:status_c) { create(:status) }

  subject(:context) { described_class.new(variant:, **options) }

  let(:options) { { role_ids: [role.id] } }

  def create_transition(old_status:, new_status:, for_role: role, **flags)
    create(:workflow, role_id: for_role.id, type_variant_id: variant.id,
                      old_status_id: old_status.id, new_status_id: new_status.id, **flags)
  end

  describe "#tab" do
    it "defaults to the always tab when none was requested" do
      expect(context.tab).to eq("always")
    end

    it "keeps a known tab" do
      expect(described_class.new(variant:, tab: "author").tab).to eq("author")
      expect(described_class.new(variant:, tab: "assignee").tab).to eq("assignee")
    end

    it "falls back to the always tab for anything unrecognised" do
      expect(described_class.new(variant:, tab: "bogus").tab).to eq("always")
    end
  end

  describe "#roles" do
    it "resolves the requested roles" do
      expect(context.roles).to contain_exactly(role)
    end

    it "falls back to the first eligible role when none was requested" do
      expect(described_class.new(variant:).roles).to contain_exactly(Workflow.ordered_eligible_roles.first)
    end
  end

  describe "#statuses" do
    before { create_transition(old_status: status_a, new_status: status_b) }

    it "spans the statuses the selected roles have transitions for" do
      expect(context.statuses).to contain_exactly(status_a, status_b)
    end

    it "is narrowed to the tab on screen" do
      author_context = described_class.new(variant:, tab: "author", role_ids: [role.id])

      expect(author_context.statuses).to be_empty
    end

    context "when the status dialog submitted a selection" do
      let(:options) { { role_ids: [role.id], status_ids: [status_a.id, status_c.id] } }

      it "uses the submitted selection instead" do
        expect(context.statuses).to contain_exactly(status_a, status_c)
      end

      it "reports the ones without transitions as newly added" do
        expect(context.added_status_ids).to contain_exactly(status_c.id)
      end

      it "reports that the selection differs from what is saved" do
        expect(context).to be_status_changes
      end
    end

    context "when the submitted selection matches what is saved" do
      let(:options) { { role_ids: [role.id], status_ids: [status_a.id, status_b.id] } }

      it "reports no additions and no changes" do
        expect(context.added_status_ids).to be_empty
        expect(context).not_to be_status_changes
      end
    end

    context "with no selection submitted" do
      it "reports no additions and no changes" do
        expect(context.added_status_ids).to be_empty
        expect(context).not_to be_status_changes
      end
    end
  end

  describe "#workflows" do
    before do
      create_transition(old_status: status_a, new_status: status_b)
      create_transition(old_status: status_b, new_status: status_c, author: true)
      create_transition(old_status: status_a, new_status: status_c, for_role: other_role)
    end

    it "returns only the selected roles' transitions for the tab on screen" do
      expect(context.workflows.map { [it.old_status_id, it.new_status_id] })
        .to contain_exactly([status_a.id, status_b.id])
    end

    it "returns the author transitions on the author tab" do
      author_context = described_class.new(variant:, tab: "author", role_ids: [role.id])

      expect(author_context.workflows.map { [it.old_status_id, it.new_status_id] })
        .to contain_exactly([status_b.id, status_c.id])
    end

    it "covers every selected role" do
      both = described_class.new(variant:, role_ids: [role.id, other_role.id])

      expect(both.workflows.map(&:role_id)).to contain_exactly(role.id, other_role.id)
    end
  end

  describe "#readonly?" do
    it "is false while the variant owns its workflows" do
      expect(context).not_to be_readonly
    end

    context "when the workflows aspect is linked to a source variant" do
      shared_let(:source_variant) { create(:type).default_variant }

      before { variant.update!(workflows_source: source_variant) }
      after { variant.update!(workflows_source: nil) }

      it "is true" do
        expect(context).to be_readonly
      end
    end
  end
end
