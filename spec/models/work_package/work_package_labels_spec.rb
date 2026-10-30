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

RSpec.describe WorkPackage, "labels" do
  let(:work_package) { create(:work_package) }
  let!(:lower_label) { create(:label, name: "apple") }
  let!(:higher_label) { create(:label, name: "zebra") }

  before do
    work_package.labels << higher_label
    work_package.labels << lower_label
  end

  it "returns labels in id order, also when preloaded" do
    preloaded = described_class.where(id: work_package.id).includes(:labels).first

    expect(work_package.reload.labels).to eq([lower_label, higher_label])
    expect(preloaded.labels).to eq([lower_label, higher_label])
  end

  it "deletes its labelings but keeps the labels when destroyed" do
    work_package.destroy!

    expect(Labeling.where(labelable: work_package)).not_to exist
    expect(Label.where(id: [lower_label.id, higher_label.id]).count).to eq(2)
  end

  it "drops a deleted label from its labels" do
    lower_label.destroy!

    expect(work_package.reload.labels).to eq([higher_label])
  end

  describe ".labeled_with" do
    it "returns only the work packages carrying the label" do
      other = create(:work_package)
      other.labels << lower_label
      create(:work_package)

      expect(described_class.labeled_with(lower_label)).to contain_exactly(work_package, other)
      expect(described_class.labeled_with(higher_label)).to contain_exactly(work_package)
    end
  end

  describe ".without_labels" do
    it "returns only the work packages without any label" do
      unlabeled = create(:work_package)

      expect(described_class.without_labels).to contain_exactly(unlabeled)
    end
  end

  describe "#label_id_replacements=" do
    before { work_package.reload }

    def persisted_label_ids = Labeling.where(labelable: work_package).pluck(:label_id)

    it "does not touch the labelings until the work package is saved" do
      work_package.label_id_replacements = [lower_label.id]

      expect(persisted_label_ids).to contain_exactly(lower_label.id, higher_label.id)

      work_package.save!

      expect(persisted_label_ids).to contain_exactly(lower_label.id)
    end

    it "adds and removes in a single save" do
      other_label = create(:label, name: "mango")
      work_package.label_id_replacements = [lower_label.id, other_label.id]
      work_package.save!

      expect(persisted_label_ids).to contain_exactly(lower_label.id, other_label.id)
    end

    it "accepts label records as well as ids" do
      work_package.label_id_replacements = [higher_label]
      work_package.save!

      expect(persisted_label_ids).to contain_exactly(higher_label.id)
    end

    it "drops blanks and duplicates" do
      work_package.label_id_replacements = ["", nil, higher_label.id, higher_label.id.to_s]

      expect(work_package.label_id_replacements).to eq([higher_label.id])
    end

    it "clears the labels when assigned an empty list" do
      work_package.label_id_replacements = []
      work_package.save!

      expect(persisted_label_ids).to be_empty
    end

    it "leaves the labels alone when assigned nil" do
      work_package.label_id_replacements = nil
      work_package.save!

      expect(persisted_label_ids).to contain_exactly(lower_label.id, higher_label.id)
    end

    it "is consumed by a single save" do
      work_package.label_id_replacements = [lower_label.id]
      work_package.save!

      Labeling.where(labelable: work_package).delete_all
      work_package.save!

      expect(persisted_label_ids).to be_empty
    end

    it "is invalid when a label does not exist, leaving the labelings alone" do
      work_package.label_id_replacements = [lower_label.id, 0]

      expect(work_package).not_to be_valid
      expect(work_package.errors.symbols_for(:labels)).to contain_exactly(:does_not_exist)
      expect(persisted_label_ids).to contain_exactly(lower_label.id, higher_label.id)
    end

    it "leaves the association writers writing through immediately" do
      work_package.label_ids = [lower_label.id]

      expect(persisted_label_ids).to contain_exactly(lower_label.id)
      expect(work_package.label_id_replacements).to be_nil
    end

    describe "#effective_labels" do
      it "returns the persisted labels when no replacements are pending" do
        expect(work_package.effective_labels).to eq([lower_label, higher_label])
      end

      it "returns the pending labels before they are saved" do
        work_package.label_id_replacements = [higher_label.id]

        expect(work_package.effective_labels).to eq([higher_label])
      end
    end

    describe "#label_changes" do
      it "is empty when nothing is pending" do
        expect(work_package.label_changes).to eq({})
      end

      it "is empty when the same set is assigned again" do
        work_package.label_id_replacements = [higher_label.id, lower_label.id]

        expect(work_package.label_changes).to eq({})
      end

      it "reports the persisted and the pending ids" do
        work_package.label_id_replacements = [lower_label.id]

        expect(work_package.label_changes)
          .to eq("labels" => [[lower_label.id, higher_label.id], [lower_label.id]])
      end
    end

    describe "attribution to the user" do
      subject(:tracked) do
        work_package.extend(OpenProject::ChangedBySystem)
        work_package
      end

      it "counts an assignment as changed by the user" do
        tracked.label_id_replacements = [lower_label.id]

        expect(tracked.changed_by_user).to include("labels")
      end

      it "does not count an assignment made by the system" do
        tracked.change_by_system do
          tracked.label_id_replacements = [lower_label.id]
        end

        expect(tracked.changed_by_user).not_to include("labels")
      end
    end
  end

  describe "#label_name_replacements=" do
    before { work_package.reload }

    def persisted_label_ids = Labeling.where(labelable: work_package).pluck(:label_id)

    it "squishes names and drops blanks" do
      work_package.label_name_replacements = ["  New   name ", "", nil, "   "]

      expect(work_package.label_name_replacements).to eq(["New name"])
    end

    it "drops case-insensitive duplicates, keeping the first spelling" do
      work_package.label_name_replacements = ["Urgent", "urgent", "URGENT", "Other"]

      expect(work_package.label_name_replacements).to eq(%w[Urgent Other])
    end

    it "stays nil when assigned nil" do
      work_package.label_name_replacements = nil

      expect(work_package.label_name_replacements).to be_nil
      expect(work_package).not_to be_override_labels
    end

    context "with names only" do
      before { work_package.label_name_replacements = ["Brand new", "APPLE"] }

      it "overrides the labels" do
        expect(work_package).to be_override_labels
      end

      it "matches existing names case-insensitively and builds unsaved labels for new ones" do
        labels = work_package.effective_labels

        expect(labels).to include(lower_label)
        new_label = labels.find { it.name == "Brand new" }
        expect(new_label).to be_new_record
        expect(Label.where(name: "Brand new")).not_to exist
      end

      it "reports the pending names as a change" do
        expect(work_package.label_changes)
          .to eq("labels" => [[lower_label.id, higher_label.id], ["Brand new", "APPLE"]])
      end

      it "is valid" do
        expect(work_package).to be_valid
      end
    end

    describe "saving" do
      it "refuses to save while label names have no ids and creates no label" do
        work_package.label_name_replacements = ["Brand new"]

        expect { expect(work_package.save).to be(false) }.not_to change(Label, :count)
        expect(work_package.errors.symbols_for(:labels)).to contain_exactly(:invalid)
        expect(persisted_label_ids).to contain_exactly(lower_label.id, higher_label.id)
      end

      it "saves once the label names are replaced with ids" do
        work_package.label_name_replacements = ["Brand new"]
        work_package.replace_label_names_with_ids([lower_label.id])
        work_package.save!

        expect(persisted_label_ids).to contain_exactly(lower_label.id)
        expect(work_package.label_name_replacements).to be_nil
      end

      it "records the labels in the journal" do
        work_package.replace_label_names_with_ids([lower_label.id])
        work_package.save!

        expect(work_package.journals.last.label_journals.pluck(:label_id)).to contain_exactly(lower_label.id)
      end
    end
  end
end
