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

RSpec.describe AdminElevationSessions::RecordUsageService, with_settings: { admin_elevation_idle_timeout: 30 } do
  shared_let(:admin) { create(:admin) }
  shared_let(:parent) { create(:project) }
  shared_let(:project) { create(:project, parent:) }
  shared_let(:other_project) { create(:project) }

  let(:last_used_at) { 10.minutes.ago.change(usec: 0) }

  def elevation_session(**)
    create(:admin_elevation_session, user: admin, project:, session_id: "session", last_used_at:, **)
  end

  subject(:result) { described_class.new(user: admin, session_id: "session").call(project:) }

  it "succeeds" do
    expect(result).to be_success
  end

  it "moves the last use of the active elevation session for the project to now" do
    used = elevation_session

    freeze_time do
      result

      expect(used.reload.last_used_at).to eq(Time.current)
    end
  end

  it "moves the last use of the active elevation session including the project as a subproject to now" do
    used = elevation_session(project: parent, include_subprojects: true)

    freeze_time do
      result

      expect(used.reload.last_used_at).to eq(Time.current)
    end
  end

  it "does not touch an elevation session for another project" do
    untouched = elevation_session(project: other_project)

    expect { result }.not_to change { untouched.reload.last_used_at }
  end

  it "does not touch an elevation session for the parent project without subprojects" do
    untouched = elevation_session(project: parent)

    expect { result }.not_to change { untouched.reload.last_used_at }
  end

  it "does not touch an elevation session of another session" do
    untouched = elevation_session(session_id: "other")

    expect { result }.not_to change { untouched.reload.last_used_at }
  end

  it "does not touch an elevation session of another admin" do
    untouched = elevation_session(user: create(:admin))

    expect { result }.not_to change { untouched.reload.last_used_at }
  end

  it "does not touch an elevation session that has ended" do
    untouched = elevation_session(ended_at: 1.minute.ago)

    expect { result }.not_to change { untouched.reload.last_used_at }
  end

  it "does not touch an elevation session that is idle" do
    untouched = elevation_session(last_used_at: 1.hour.ago.change(usec: 0))

    expect { result }.not_to change { untouched.reload.last_used_at }
  end
end
