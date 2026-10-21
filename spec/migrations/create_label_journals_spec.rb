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
require Rails.root.join("db/migrate/20261021120000_create_label_journals.rb")

RSpec.describe CreateLabelJournals, type: :model,
                                    with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  let(:label) { create(:label) }
  let(:other_label) { create(:label) }

  let!(:labelled_work_package) { create(:work_package, labels: [label, other_label]) }
  let!(:unlabelled_work_package) { create(:work_package) }

  before do
    labelled_work_package.update!(subject: "Second journal")

    # Journals and labelings exist but the snapshot table does not yet.
    ActiveRecord::Base.connection.drop_table(:label_journals)
  end

  it "snapshots the current labels onto the latest journal only" do
    migrate

    first_journal, latest_journal = labelled_work_package.journals.order(:version).to_a

    expect(Journal::LabelJournal.pluck(:journal_id, :label_id))
      .to contain_exactly([latest_journal.id, label.id], [latest_journal.id, other_label.id])
    expect(Journal::LabelJournal.where(journal_id: first_journal.id)).to be_empty
  end

  it "creates no rows for work packages without labels" do
    migrate

    expect(Journal::LabelJournal.where(journal: unlabelled_work_package.journals)).to be_empty
  end

  it "does not journal a change when a labelled work package is saved unchanged" do
    migrate
    labelled_work_package.reload

    expect do
      labelled_work_package.label_id_replacements = [label.id, other_label.id]
      labelled_work_package.save!
    end.not_to change { labelled_work_package.journals.count }
  end

  it "journals the removal when all labels are removed as the first edit" do
    migrate
    labelled_work_package.reload

    expect do
      labelled_work_package.label_id_replacements = []
      labelled_work_package.save!
    end.to change { labelled_work_package.journals.count }.by(1)

    expect(labelled_work_package.last_journal.details["labels"])
      .to eq([[label.id, other_label.id].sort.join(","), nil])
  end
end
