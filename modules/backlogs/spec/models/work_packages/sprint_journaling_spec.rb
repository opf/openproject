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

RSpec.describe "WorkPackage sprint association journaling", # rubocop:disable RSpec/DescribeClass
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project) }
  shared_let(:sprint1) { create(:sprint, name: "Sprint 1", project:) }
  shared_let(:sprint2) { create(:sprint, name: "Sprint 2", project:) }
  shared_let(:work_package_with_sprint) do
    create(:work_package, :created_in_past, created_at: 1.day.ago, project:, sprint: sprint1)
  end
  shared_let(:work_package_without_sprint) { create(:work_package, :created_in_past, created_at: 1.day.ago, project:) }

  it "creates a journal entry when sprint is assigned" do
    expect do
      work_package_without_sprint.update!(sprint: sprint1)
    end.to change(Journal::WorkPackageJournal, :count).by(1)

    last_journal = work_package_without_sprint.journals.last
    expect(last_journal.details).to have_key("sprint_id")
    expect(last_journal.details["sprint_id"]).to eq([nil, sprint1.id])
  end

  it "creates a journal entry when sprint is changed" do
    expect do
      work_package_with_sprint.update!(sprint: sprint2)
    end.to change(Journal::WorkPackageJournal, :count).by(1)

    last_journal = work_package_with_sprint.journals.last
    expect(last_journal.details).to have_key("sprint_id")
    expect(last_journal.details["sprint_id"]).to eq([sprint1.id, sprint2.id])
  end

  it "creates a journal entry when sprint is removed" do
    expect do
      work_package_with_sprint.update!(sprint: nil)
    end.to change(Journal::WorkPackageJournal, :count).by(1)

    last_journal = work_package_with_sprint.journals.last
    expect(last_journal.details).to have_key("sprint_id")
    expect(last_journal.details["sprint_id"]).to eq([sprint1.id, nil])
  end

  it "formats the sprint change in the journal" do
    work_package_with_sprint.update!(sprint: sprint2)

    last_journal = work_package_with_sprint.journals.last
    formatted = last_journal.render_detail("sprint_id", no_html: true)

    expect(formatted).to include("Sprint 1")
    expect(formatted).to include("Sprint 2")
  end
end
