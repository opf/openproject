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

RSpec.describe AdminElevationSessions::EndAllService do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let!(:in_session) { create(:admin_elevation_session, user: admin, project:, session_id: "session") }
  let!(:in_other_session) { create(:admin_elevation_session, user: admin, project:, session_id: "other") }

  it "ends all open elevation sessions of the user", :aggregate_failures do
    freeze_time do
      expect(described_class.new(user: admin).call).to be_success

      expect(in_session.reload.ended_at).to eq(Time.current)
      expect(in_other_session.reload.ended_at).to eq(Time.current)
    end
  end

  it "ends all open elevation sessions except those of the given session", :aggregate_failures do
    freeze_time do
      described_class.new(user: admin).call(except_session_id: "session")

      expect(in_session.reload.ended_at).to be_nil
      expect(in_other_session.reload.ended_at).to eq(Time.current)
    end
  end

  it "keeps the original end of elevation sessions that have already ended" do
    ended_at = 1.hour.ago.change(usec: 0)
    ended = create(:admin_elevation_session, user: admin, project:, ended_at:)

    described_class.new(user: admin).call

    expect(ended.reload.ended_at).to eq(ended_at)
  end

  it "does not end the elevation sessions of another admin" do
    other = create(:admin_elevation_session, user: create(:admin), project:)

    described_class.new(user: admin).call

    expect(other.reload.ended_at).to be_nil
  end
end
