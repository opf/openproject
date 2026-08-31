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
require Rails.root.join("db/migrate/20260707090000_create_work_package_version_journals.rb")

RSpec.describe CreateWorkPackageVersionJournals, type: :model,
                                                 with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  let(:project) { create(:project) }
  let(:version) { create(:version, project:) }
  let(:other_version) { create(:version, project:) }

  let!(:work_package_with_version) { create(:work_package, project:, version_id: version.id) }
  let!(:work_package_without_version) { create(:work_package, project:, version_id: nil) }

  before do
    # A second journal with a different version, so the backfill has to
    # reconstruct a distinct target set per journal, not per work package.
    work_package_with_version.update!(version_id: other_version.id)

    # Journals exist but the snapshot table does not yet.
    ActiveRecord::Base.connection.drop_table(:work_package_version_journals)
  end

  it "succeeds" do
    expect { migrate }.not_to raise_error
  end

  it "creates a target snapshot row per journal, matching that journal's version_id" do
    migrate

    first_journal, second_journal = work_package_with_version.journals.order(:version)

    expect(Journal::WorkPackageVersionJournal.pluck(:journal_id, :version_id, :kind))
      .to contain_exactly([first_journal.id, version.id, "target"],
                          [second_journal.id, other_version.id, "target"])
  end

  it "creates no rows for journals without a version" do
    migrate

    expect(Journal::WorkPackageVersionJournal.where(journal: work_package_without_version.journals))
      .to be_empty
  end
end
