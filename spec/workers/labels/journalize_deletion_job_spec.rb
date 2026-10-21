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

RSpec.describe Labels::JournalizeDeletionJob, type: :job, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:admin) { create(:admin) }

  let(:label) { create(:label, name: "Deprecated") }
  let(:label_id) { label.id }
  let(:label_name) { label.name }
  let(:labels_on_work_packages) { [label] }
  let(:work_packages) do
    create_list(:work_package, 2, journals: { 10.minutes.ago => { user: admin } })
  end
  let(:user_id) { admin.id }
  let(:cause) do
    { "type" => "label_deleted", "label_ids" => [label_id], "label_names" => [label_name] }
  end

  def perform
    described_class.perform_now(work_package_ids: work_packages.map(&:id), label_id:, label_name:, user_id:)
  end

  before do
    work_packages.each do |work_package|
      WorkPackages::UpdateService.new(user: admin, model: work_package).call(label_ids: labels_on_work_packages.map(&:id)).on_failure { raise it.message }
    end
    label.destroy!
  end

  it "writes one journal per work package, authored by the admin, recording the label as removed" do
    expect { perform }.to change(Journal, :count).by(2)

    work_packages.each do |work_package|
      journal = work_package.reload.last_journal
      expect(journal.user).to eq(admin)
      expect(journal.cause).to eq(cause)
    end

    journal = work_packages.first.reload.last_journal
    old_ids, new_ids = journal.details["labels"].map { it.to_s.split(",").map(&:to_i) }
    expect(old_ids).to include(label_id)
    expect(new_ids).not_to include(label_id)
    expect(journal.render_detail(["labels", journal.details["labels"]], html: false))
      .to include(I18n.t(:label_deleted_label))
  end

  it "adds no further journal when run again with the same arguments" do
    perform

    expect { perform }.not_to change(Journal, :count)
  end

  context "when the admin no longer exists" do
    let(:user_id) { 0 }

    it "authors the journals as the deleted user" do
      perform

      expect(work_packages.first.reload.last_journal.user).to eq(DeletedUser.first)
    end
  end

  context "when the same admin deletes another label right after" do
    let(:work_packages) { [create(:work_package, journals: { 10.minutes.ago => { user: admin } })] }
    let(:other_label) { create(:label, name: "Obsolete") }
    let(:labels_on_work_packages) { [label, other_label] }
    let(:work_package) { work_packages.first }

    def perform_for(deleted_label)
      described_class.perform_now(work_package_ids: [work_package.id], label_id: deleted_label.id,
                                  label_name: deleted_label.name, user_id:)
    end

    before do
      WorkPackages::UpdateService.new(user: admin, model: work_package).call(subject: "x").on_failure { raise it.message }
      with_settings(journal_aggregation_time_minutes: 5)
      perform_for(label)
      other_label.destroy!
    end

    it "merges both labels into one journal entry" do
      expect { perform_for(other_label) }.not_to change { work_package.journals.count }

      journal = work_package.reload.last_journal
      expect(journal.cause).to eq(
        "type" => "label_deleted",
        "label_ids" => [label.id, other_label.id],
        "label_names" => [label.name, other_label.name]
      )
      new_ids = journal.details["labels"].last.to_s.split(",").map(&:to_i)
      expect(new_ids).not_to include(label.id, other_label.id)
    end

    it "adds nothing when the first label's job runs again after the merge" do
      perform_for(other_label)

      expect { perform_for(label) }.not_to change { work_package.journals.count }
    end
  end
end
