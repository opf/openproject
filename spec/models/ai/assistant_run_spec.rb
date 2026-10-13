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

RSpec.describe AI::AssistantRun do
  subject(:run) { create(:ai_assistant_run) }

  it "starts as running" do
    expect(run).to be_running
    expect(run).not_to be_finished
  end

  it "records what was not checked" do
    run.add_not_checked(:pull_requests, :module_disabled)
    run.save!

    expect(run.reload.not_checked).to eq([{ "area" => "pull_requests", "reason" => "module_disabled" }])
  end

  describe ".for" do
    let!(:other_users_run) { create(:ai_assistant_run, work_package: run.work_package) }

    it "returns only the runs of that user on that work package" do
      expect(described_class.for(run.user, run.work_package)).to eq([run])
    end
  end

  it "is deleted with its user" do
    run
    run.user.destroy

    expect(described_class.exists?(run.id)).to be(false)
  end

  it "is deleted with its work package" do
    run
    run.work_package.destroy

    expect(described_class.exists?(run.id)).to be(false)
  end
end
