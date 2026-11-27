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
require Rails.root.join("modules/backlogs/db/migrate/20261002090000_remove_status_from_sprints")

RSpec.describe RemoveStatusFromSprints, type: :model do
  subject(:migrate) do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
    Sprint.reset_column_information
  end

  # The schema changes are rolled back together with the example's transaction.
  before do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }
    Sprint.reset_column_information
  end

  after { Sprint.reset_column_information }

  def insert_sprint(status:, start_date: nil, finish_date: nil, started_at: nil, completed_at: nil)
    Sprint.connection.select_value(<<~SQL.squish)
      INSERT INTO sprints (name, project_id, status, start_date, finish_date, started_at, completed_at,
                           created_at, updated_at)
      VALUES ('Sprint', #{project.id}, #{Sprint.connection.quote(status)},
              #{Sprint.connection.quote(start_date)}, #{Sprint.connection.quote(finish_date)},
              #{Sprint.connection.quote(started_at)}, #{Sprint.connection.quote(completed_at)},
              '2026-01-01 08:00:00+00', '2026-03-01 18:00:00+00')
      RETURNING id
    SQL
  end

  let(:project) { create(:project) }

  it "removes the status column" do
    migrate

    expect(Sprint.column_names).not_to include("status")
  end

  it "backfills started_at with the beginning of start_date for an active sprint" do
    id = insert_sprint(status: "active", start_date: Date.new(2026, 1, 5), finish_date: Date.new(2026, 1, 20))
    migrate

    expect(Sprint.find(id)).to have_attributes(status: "active",
                                               started_at: Time.zone.parse("2026-01-05 00:00:00 UTC"),
                                               completed_at: nil)
  end

  it "backfills completed_at with the end of finish_date for a completed sprint" do
    id = insert_sprint(status: "completed", start_date: Date.new(2026, 2, 1), finish_date: Date.new(2026, 2, 14))
    migrate

    sprint = Sprint.find(id)
    expect(sprint.status).to eq("completed")
    expect(sprint.started_at).to eq(Time.zone.parse("2026-02-01 00:00:00 UTC"))
    expect(sprint.completed_at).to eq(Time.zone.parse("2026-02-14 23:59:59.999999 UTC"))
  end

  it "falls back to created_at and updated_at for a completed sprint without dates" do
    id = insert_sprint(status: "completed")
    migrate

    expect(Sprint.find(id)).to have_attributes(status: "completed",
                                               started_at: Time.zone.parse("2026-01-01 08:00:00 UTC"),
                                               completed_at: Time.zone.parse("2026-03-01 18:00:00 UTC"))
  end

  it "keeps timestamps that are already set" do
    started_at = Time.zone.parse("2026-04-01 09:17:42 UTC")
    completed_at = Time.zone.parse("2026-04-14 16:03:11 UTC")
    id = insert_sprint(status: "completed", start_date: Date.new(2026, 4, 1), finish_date: Date.new(2026, 4, 14),
                       started_at:, completed_at:)
    migrate

    expect(Sprint.find(id)).to have_attributes(status: "completed", started_at:, completed_at:)
  end

  it "clears timestamps contradicting the stored status" do
    in_planning_id = insert_sprint(status: "in_planning", started_at: 1.day.ago, completed_at: 1.hour.ago)
    active_id = insert_sprint(status: "active", start_date: Date.new(2026, 1, 5), finish_date: Date.new(2026, 1, 20),
                              started_at: 1.day.ago, completed_at: 1.hour.ago)
    migrate

    expect(Sprint.find(in_planning_id)).to have_attributes(status: "in_planning", started_at: nil, completed_at: nil)
    expect(Sprint.find(active_id)).to have_attributes(status: "active", completed_at: nil)
  end
end
