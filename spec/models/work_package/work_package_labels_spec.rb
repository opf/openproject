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

  describe "#label_changes" do
    # A record that carries the labels of the outer setup without the bookkeeping
    # of having assigned them, as in any request loading it fresh.
    subject(:labeled) { described_class.find(work_package.id) }

    it "is empty when the labels were not touched" do
      expect(labeled.label_changes).to eq({})
    end

    it "is empty when the same set is assigned again" do
      labeled.label_ids = [higher_label.id, lower_label.id]

      expect(labeled.label_changes).to eq({})
    end

    it "reports the ids before and after an assignment" do
      labeled.label_ids = [lower_label.id]

      expect(labeled.label_changes)
        .to eq("labels" => [[lower_label.id, higher_label.id], [lower_label.id]])
    end

    it "reports a label added to the collection" do
      other_label = create(:label, name: "mango")
      labeled.labels << other_label

      expect(labeled.label_changes)
        .to eq("labels" => [[lower_label.id, higher_label.id], [lower_label.id, higher_label.id, other_label.id]])
    end

    it "reports a label removed from the collection" do
      labeled.labels.delete(higher_label)

      expect(labeled.label_changes)
        .to eq("labels" => [[lower_label.id, higher_label.id], [lower_label.id]])
    end

    it "keeps reporting the set the changes started from" do
      other_label = create(:label, name: "mango")
      labeled.labels.delete(higher_label)
      labeled.labels << other_label

      expect(labeled.label_changes)
        .to eq("labels" => [[lower_label.id, higher_label.id], [lower_label.id, other_label.id]])
    end

    it "starts over after the work package was saved" do
      labeled.label_ids = [lower_label.id]
      labeled.save!

      expect(labeled.label_changes).to eq({})
    end
  end

  describe "attribution to the user" do
    subject(:tracked) do
      described_class.find(work_package.id).extend(OpenProject::ChangedBySystem)
    end

    it "counts an assignment as changed by the user" do
      tracked.label_ids = [lower_label.id]

      expect(tracked.changed_by_user).to include("labels")
    end

    it "does not count an assignment made by the system" do
      tracked.change_by_system do
        tracked.label_ids = [lower_label.id]
      end

      expect(tracked.changed_by_user).not_to include("labels")
    end
  end
end
