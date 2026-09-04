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

RSpec.describe AI::Runs::CleanupJob, with_config: { ai_run_retention_seconds: 600 } do
  def run_finished(ago)
    create(:ai_run, :succeeded, finished_at: ago.ago).tap { |run| run.append_event("completed") }
  end

  it "deletes expired runs together with their events" do
    expired = run_finished(20.minutes)

    expect { described_class.perform_now }
      .to change { AI::Run.exists?(expired.id) }.from(true).to(false)
      .and change { AI::RunEvent.where(run_id: expired.id).count }.from(1).to(0)
  end

  it "keeps runs finished within the retention period" do
    recent = run_finished(5.minutes)

    described_class.perform_now

    expect(AI::Run.exists?(recent.id)).to be(true)
  end

  it "deletes unfinished runs created before the retention period" do
    stale = create(:ai_run, :running, created_at: 20.minutes.ago)

    described_class.perform_now

    expect(AI::Run.exists?(stale.id)).to be(false)
  end

  context "with a retention below the minimum", with_config: { ai_run_retention_seconds: 60 } do
    it "still keeps a run finished 4 minutes ago" do
      recent = run_finished(4.minutes)

      described_class.perform_now

      expect(AI::Run.exists?(recent.id)).to be(true)
    end
  end
end
