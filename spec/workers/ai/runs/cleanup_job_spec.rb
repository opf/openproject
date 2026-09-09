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
  it "deletes expired runs together with their events" do
    expired = create(:ai_text_transform_run, :succeeded, finished_at: 11.minutes.ago)
    expired.append_event("status", status: "running")
    kept = create(:ai_text_transform_run, :succeeded, finished_at: 1.minute.ago)

    described_class.perform_now

    expect(AI::TextTransformRun.exists?(expired.id)).to be(false)
    expect(AI::TextTransformRunEvent.where(run_id: expired.id)).to be_empty
    expect(AI::TextTransformRun.exists?(kept.id)).to be(true)
  end

  it "keeps a run within the minimum retention even if configured lower", with_config: { ai_run_retention_seconds: 10 } do
    recent = create(:ai_text_transform_run, :succeeded, finished_at: 4.minutes.ago)

    described_class.perform_now

    expect(AI::TextTransformRun.exists?(recent.id)).to be(true)
  end
end
