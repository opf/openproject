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
require Rails.root.join("modules/backlogs/db/migrate/20260615000000_add_backlog_bucket_id_to_work_package_journals")

RSpec.describe AddBacklogBucketIdToWorkPackageJournals, type: :model,
                                                        with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  let(:project) { create(:project) }
  let(:sprint) { create(:sprint, project:) }
  let(:bucket) { create(:backlog_bucket, project:) }
  let(:other_bucket) { create(:backlog_bucket, project:) }

  let!(:work_package_with_bucket) { create(:work_package, project:, backlog_bucket: bucket) }
  let!(:work_package_without_bucket) { create(:work_package, project:, backlog_bucket: nil) }
  let!(:work_package_previously_sprinted) { create(:work_package, project:, sprint:) }

  before do
    # The bucket was reassigned once, so the work package has several
    # journals with different historical backlog_bucket_id values. Only its
    # *current* bucket is known, so the backfill has to apply that to every
    # one of them, not just the latest.
    work_package_with_bucket.update!(backlog_bucket: other_bucket)

    # The work package used to be in a sprint before it was moved to a
    # bucket. Its older journal, recorded while it still had the sprint,
    # must not be backfilled with the bucket it only got afterwards.
    work_package_previously_sprinted.update!(sprint: nil, backlog_bucket: bucket)

    # The column already exists in the test schema (this migration added
    # it); drop it to simulate the pre-migration state the backfill runs
    # against.
    ActiveRecord::Base.connection.remove_column(:work_package_journals, :backlog_bucket_id)
  end

  it "succeeds" do
    expect { migrate }.not_to raise_error
  end

  it "sets every journal's backlog_bucket_id to the work package's current bucket" do
    migrate

    data_ids = work_package_with_bucket.journals.pluck(:data_id)
    expect(data_ids.size).to be >= 2
    expect(Journal::WorkPackageJournal.where(id: data_ids).pluck(:backlog_bucket_id))
      .to all(eq(other_bucket.id))
  end

  it "leaves journals of work packages without a bucket untouched" do
    migrate

    data_ids = work_package_without_bucket.journals.pluck(:data_id)
    expect(Journal::WorkPackageJournal.where(id: data_ids).pluck(:backlog_bucket_id))
      .to all(be_nil)
  end

  it "leaves journals recorded while the work package still had a sprint untouched" do
    migrate

    data_ids = work_package_previously_sprinted.journals.pluck(:data_id)
    buckets_by_sprint_id = Journal::WorkPackageJournal.where(id: data_ids)
                                                       .pluck(:sprint_id, :backlog_bucket_id)
                                                       .to_h

    expect(buckets_by_sprint_id[sprint.id]).to be_nil
    expect(buckets_by_sprint_id[nil]).to eq(bucket.id)
  end
end
