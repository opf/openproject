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

RSpec.describe "WorkPackage backlog_bucket association journaling", # rubocop:disable RSpec/DescribeClass
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_current_user { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:bucket1) { create(:backlog_bucket, name: "Bucket 1", project:) }
  shared_let(:bucket2) { create(:backlog_bucket, name: "Bucket 2", project:) }
  shared_let(:work_package_with_bucket) do
    create(:work_package, :created_in_past, created_at: 1.day.ago, project:, backlog_bucket: bucket1)
  end
  shared_let(:work_package_without_bucket) { create(:work_package, :created_in_past, created_at: 1.day.ago, project:) }

  it "creates a journal entry when backlog_bucket is assigned" do
    expect do
      work_package_without_bucket.update!(backlog_bucket: bucket1)
    end.to change(Journal::WorkPackageJournal, :count).by(1)

    last_journal = work_package_without_bucket.journals.last
    expect(last_journal.details).to have_key("backlog_bucket_id")
    expect(last_journal.details["backlog_bucket_id"]).to eq([nil, bucket1.id])
  end

  it "creates a journal entry when backlog_bucket is changed" do
    expect do
      work_package_with_bucket.update!(backlog_bucket: bucket2)
    end.to change(Journal::WorkPackageJournal, :count).by(1)

    last_journal = work_package_with_bucket.journals.last
    expect(last_journal.details).to have_key("backlog_bucket_id")
    expect(last_journal.details["backlog_bucket_id"]).to eq([bucket1.id, bucket2.id])
  end

  it "creates a journal entry when backlog_bucket is removed" do
    expect do
      work_package_with_bucket.update!(backlog_bucket: nil)
    end.to change(Journal::WorkPackageJournal, :count).by(1)

    last_journal = work_package_with_bucket.journals.last
    expect(last_journal.details).to have_key("backlog_bucket_id")
    expect(last_journal.details["backlog_bucket_id"]).to eq([bucket1.id, nil])
  end

  it "formats the backlog_bucket change in the journal" do
    work_package_with_bucket.update!(backlog_bucket: bucket2)

    last_journal = work_package_with_bucket.journals.last
    result = last_journal.render_detail("backlog_bucket_id", html: false)

    expect(result).to include("Bucket 1")
    expect(result).to include("Bucket 2")
    expect(result).not_to include(I18n.t(:text_journal_permission_denied))
  end

  context "when user lacks :view_sprints permission" do
    current_user { create(:user) }
    before { mock_permissions_for(User.current, &:forbid_everything) }

    it "renders a permission denied message instead of the bucket name" do
      last_journal = work_package_with_bucket.journals.last

      result = last_journal.render_detail("backlog_bucket_id", html: true)

      expect(result).to include(I18n.t(:text_journal_permission_denied))
      expect(result).not_to include("Bucket 1")
    end

    it "renders a permission denied message in plain text" do
      last_journal = work_package_with_bucket.journals.last

      result = last_journal.render_detail("backlog_bucket_id", html: false)
      expect(result).to include(I18n.t(:text_journal_permission_denied))
      expect(result).not_to include("Bucket 1")
    end
  end
end
