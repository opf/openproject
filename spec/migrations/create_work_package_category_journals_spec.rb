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
require Rails.root.join("db/migrate/20260805090200_create_work_package_category_journals.rb")

RSpec.describe CreateWorkPackageCategoryJournals, type: :model,
                                                  with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  let(:project) { create(:project) }
  let(:category) { create(:category, project:) }
  let(:other_category) { create(:category, project:) }

  let!(:work_package_with_category) { create(:work_package, project:, category:) }
  let!(:work_package_without_category) { create(:work_package, project:, category: nil) }

  before do
    # A second journal with a different category, so the backfill has to
    # reconstruct a distinct set per journal, not per work package.
    work_package_with_category.update!(category: other_category)

    # Journals exist but the snapshot table does not yet.
    ActiveRecord::Base.connection.drop_table(:work_package_category_journals)
  end

  it "succeeds" do
    expect { migrate }.not_to raise_error
  end

  it "creates a snapshot row per journal, matching that journal's category_id" do
    migrate

    first_journal, second_journal = work_package_with_category.journals.order(:version)

    expect(Journal::WorkPackageCategoryJournal.pluck(:journal_id, :category_id))
      .to contain_exactly([first_journal.id, category.id],
                          [second_journal.id, other_category.id])
  end

  it "creates no rows for journals without a category" do
    migrate

    expect(Journal::WorkPackageCategoryJournal.where(journal: work_package_without_category.journals))
      .to be_empty
  end
end
