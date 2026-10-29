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

RSpec.describe Import::JiraCreateLabelsJob do
  include_context "with a jira demo issue"

  def references
    Import::JiraOpenProjectReference.where(jira_import:, op_entity_class: "Label")
  end

  describe "#perform" do
    let(:jira_issue_payload) do
      super().tap { |payload| payload["fields"]["labels"] = %w[backend urgent] }
    end

    it "creates a label per distinct jira label of the import" do
      expect { create_labels }.to change(Label, :count).by(2)

      expect(Label.pluck(:name)).to contain_exactly("backend", "urgent")
    end

    it "authors the labels as the system user" do
      create_labels

      expect(Label.distinct.pluck(:author_id)).to eq([User.system.id])
    end

    it "references the created labels so the revert can remove them" do
      create_labels

      expect(references.pluck(:uses_existing)).to eq([false, false])
      expect(references.map { |ref| ref.op_leg.name }).to contain_exactly("backend", "urgent")
    end

    it "creates nothing new when the import is run again" do
      create_labels

      expect { create_labels }.to not_change(Label, :count).and not_change(references, :count)
    end

    it "keeps its own labels revertable when the import is run again" do
      create_labels
      create_labels

      expect(references.pluck(:uses_existing)).to eq([false, false])
    end

    context "when the reference cannot be written" do
      before do
        allow(Import::JiraOpenProjectReference).to receive(:upsert_all).and_raise("reference write failed")
      end

      it "rolls the label back, so a retry cannot mistake it for a pre-existing one" do
        expect { create_labels }.to raise_error("reference write failed")

        expect(Label.count).to eq(0)
      end
    end

    context "when several issues share a label" do
      let!(:jira_issue2) do
        payload = jira_issue_payload.deep_dup.tap do |p|
          p["id"] = "10406"
          p["key"] = "DPPP-7"
          p["fields"]["labels"] = %w[backend Backend]
        end
        create(:jira_issue, jira_import:, origin_id: "10406", jira_project:, payload:)
      end

      it "creates it once, ignoring case" do
        expect { create_labels }.to change(Label, :count).by(2)
      end
    end

    context "when a label with the same name already exists in a different case" do
      let!(:existing_label) { create(:label, name: "Backend") }

      it "reuses it instead of creating a second one" do
        expect { create_labels }.to change(Label, :count).by(1)

        expect(Label.named("backend").first).to eq(existing_label)
      end

      it "references it as pre-existing, so the revert leaves it alone" do
        create_labels

        expect(references.where(uses_existing: true).map(&:op_leg)).to eq([existing_label])
        expect(references.where(uses_existing: false).map { |ref| ref.op_leg.name }).to eq(["urgent"])
      end

      it "still references it as pre-existing when the import is run again" do
        create_labels
        create_labels

        expect(references.where(uses_existing: true).map(&:op_leg)).to eq([existing_label])
      end
    end

    context "when the issues of two projects share a label" do
      let!(:other_jira_project) { create(:jira_project, jira_import:, payload: jira_project_payload) }

      let!(:other_project_issue) do
        payload = jira_issue_payload.deep_dup.tap { |p| p["fields"]["labels"] = %w[backend] }
        create(:jira_issue, jira_import:, jira_project: other_jira_project, payload:)
      end

      it "creates the shared label once" do
        expect { create_labels }.to change(Label, :count).by(2)

        expect(Label.named("backend").count).to eq(1)
      end
    end

    context "when the issues of another import carry labels" do
      let(:other_jira_import) { create(:jira_import, jira:, author:) }

      let!(:other_jira_issue) do
        payload = jira_issue_payload.deep_dup.tap { |p| p["fields"]["labels"] = %w[elsewhere] }
        create(:jira_issue, jira_import: other_jira_import, origin_id: "10407", jira_project:, payload:)
      end

      it "ignores them" do
        create_labels

        expect(Label.named("elsewhere")).to be_empty
      end
    end

    context "when no issue carries a label" do
      let(:jira_issue_payload) { super().tap { |payload| payload["fields"]["labels"] = [] } }

      it "creates nothing" do
        expect { create_labels }.not_to change(Label, :count)
      end
    end

    context "when the labels field is hidden in the jira field configuration" do
      let(:jira_issue_payload) { super().tap { |payload| payload["fields"].delete("labels") } }

      it "creates nothing" do
        expect { create_labels }.not_to change(Label, :count)
      end
    end

    context "when the labels field is not an array" do
      let(:jira_issue_payload) do
        super().tap { |payload| payload["fields"]["labels"] = "backend" }
      end

      it "creates nothing" do
        expect { create_labels }.not_to change(Label, :count)
      end
    end

    context "when label names are padded, blank or null" do
      let(:jira_issue_payload) do
        super().tap { |payload| payload["fields"]["labels"] = ["  backend  ", "   ", nil] }
      end

      it "squishes them and skips the ones left empty" do
        expect { create_labels }.to change(Label, :count).by(1)

        expect(Label.pluck(:name)).to eq(["backend"])
      end
    end
  end
end
